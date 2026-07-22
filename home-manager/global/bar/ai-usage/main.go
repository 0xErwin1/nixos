// Command epsilon-ai-usage is a provider-agnostic AI usage fetcher for the Astal
// bar's "extras" panel.
//
// It reads the local OAuth credentials that the Claude Code, Codex, and Grok
// Build CLIs maintain, queries each provider's usage endpoint, and prints a
// single normalized JSON document to stdout:
//
//	{
//	  "generatedAt": "2026-07-16T18:00:00Z",
//	  "providers": [
//	    {"id":"claude","name":"Claude","plan":"max","available":true,"reason":null,
//	     "windows":[
//	       {"label":"5h","usedPercent":19,"resetAt":"2026-...Z"},
//	       {"label":"Weekly","usedPercent":13,"resetAt":"2026-...Z"}]},
//	    {"id":"codex", ...}
//	  ]
//	}
//
// Adding a provider = adding one *Provider() func that returns this shape; the
// bar renders whatever it gets. Access tokens are never written to stdout/stderr.
//
// When an access token is expired (or a usage call returns 401) the matching
// OAuth refresh flow runs and the rotated tokens are written back atomically.
// Only the token sub-object is re-marshalled, so sibling top-level keys in the
// credential file keep their exact bytes.
package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/fs"
	"math"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

const httpTimeout = 20 * time.Second

const (
	claudeUsageURL   = "https://api.anthropic.com/api/oauth/usage"
	claudeRefreshURL = "https://console.anthropic.com/v1/oauth/token"
	claudeClientID   = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"

	codexUsageURL   = "https://chatgpt.com/backend-api/wham/usage"
	codexRefreshURL = "https://auth.openai.com/oauth/token"
	codexClientID   = "app_EMoamEEZ73f0CkXaXp7hrann"

	// Grok Build (xAI SuperGrok / X Premium+). Credentials live in ~/.grok/auth.json
	// after `grok login`. Billing is exposed on the CLI chat proxy; identity/plan
	// come from the user endpoint. OIDC refresh uses auth.x.ai (form-encoded).
	grokUserURL     = "https://cli-chat-proxy.grok.com/v1/user?include=subscription"
	grokBillingURL  = "https://cli-chat-proxy.grok.com/v1/billing?format=credits"
	grokBillingRaw  = "https://cli-chat-proxy.grok.com/v1/billing"
	grokRefreshURL  = "https://auth.x.ai/oauth2/token"
	grokOIDCPrefix  = "https://auth.x.ai::"
)

var (
	httpClient = &http.Client{Timeout: httpTimeout}
	claudePath = homePath(".claude/.credentials.json")
	codexPath  = homePath(".codex/auth.json")
	grokPath   = homePath(".grok/auth.json")
)

// ── normalized output ───────────────────────────────────────────────────────

type window struct {
	Label       string  `json:"label"`
	UsedPercent int     `json:"usedPercent"`
	ResetAt     *string `json:"resetAt"`
}

// A free-form label/value stat rendered under the windows (extra/overage spend,
// reset credits, …). Provider-agnostic: the bar renders whatever notes it gets.
type note struct {
	Label string `json:"label"`
	Value string `json:"value"`
}

// Daily token/cost usage estimated from local session logs.
type dayCost struct {
	Date   string  `json:"date"`
	Tokens int64   `json:"tokens"`
	EstUsd float64 `json:"estUsd"`
}

// Per-model token/cost totals over the same window, so the panel can show where
// spend concentrates by model tier.
type modelCost struct {
	Model  string  `json:"model"`
	Tokens int64   `json:"tokens"`
	EstUsd float64 `json:"estUsd"`
}

type costSummary struct {
	Today  dayCost     `json:"today"`
	Week   dayCost     `json:"week"`
	Days   []dayCost   `json:"days"`
	Models []modelCost `json:"models"`
}

type provider struct {
	ID        string       `json:"id"`
	Name      string       `json:"name"`
	Plan      *string      `json:"plan"`
	Available bool         `json:"available"`
	Reason    *string      `json:"reason"`
	Windows   []window     `json:"windows"`
	Notes     []note       `json:"notes"`
	Cost      *costSummary `json:"cost"`
}

type output struct {
	GeneratedAt string     `json:"generatedAt"`
	Providers   []provider `json:"providers"`
}

// ── helpers ─────────────────────────────────────────────────────────────────

func homePath(rel string) string {
	home, _ := os.UserHomeDir()
	return filepath.Join(home, rel)
}

func ptr(s string) *string { return &s }

func str(m map[string]any, key string) string {
	if v, ok := m[key].(string); ok {
		return v
	}
	return ""
}

func isoFromEpoch(sec int64) *string {
	if sec <= 0 {
		return nil
	}
	return ptr(time.Unix(sec, 0).UTC().Format("2006-01-02T15:04:05Z"))
}

// windowLabel derives a human label from a window length instead of hardcoding
// it: a provider/plan may expose a 5h window, a weekly one, or something else.
func windowLabel(seconds int64) string {
	switch {
	case seconds <= 0:
		return "?"
	case seconds <= 6*3600:
		return fmt.Sprintf("%dh", int(math.Round(float64(seconds)/3600)))
	}
	days := int(math.Round(float64(seconds) / 86400))
	if days == 7 {
		return "Weekly"
	}
	return fmt.Sprintf("%dd", days)
}

func httpJSON(method, url string, headers map[string]string, body []byte) (int, []byte, error) {
	var reader io.Reader
	if body != nil {
		reader = bytes.NewReader(body)
	}

	req, err := http.NewRequest(method, url, reader)
	if err != nil {
		return 0, nil, err
	}
	for k, v := range headers {
		req.Header.Set(k, v)
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := httpClient.Do(req)
	if err != nil {
		return 0, nil, err
	}
	defer resp.Body.Close()

	data, err := io.ReadAll(resp.Body)
	return resp.StatusCode, data, err
}

// atomicWrite replaces path via a temp file in the same directory + rename, so a
// crash mid-write never leaves a truncated credential file.
func atomicWrite(path string, data []byte) error {
	f, err := os.CreateTemp(filepath.Dir(path), ".ai-usage-*")
	if err != nil {
		return err
	}
	tmp := f.Name()

	if _, err := f.Write(data); err != nil {
		f.Close()
		os.Remove(tmp)
		return err
	}
	if err := f.Close(); err != nil {
		os.Remove(tmp)
		return err
	}
	_ = os.Chmod(tmp, 0o600)
	return os.Rename(tmp, path)
}

type tokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	IDToken      string `json:"id_token"`
	ExpiresIn    int64  `json:"expires_in"`
}

func oauthRefresh(url, refreshToken, clientID string) (tokenResponse, bool) {
	var tr tokenResponse
	if refreshToken == "" {
		return tr, false
	}

	body, _ := json.Marshal(map[string]string{
		"grant_type":    "refresh_token",
		"refresh_token": refreshToken,
		"client_id":     clientID,
	})

	status, data, err := httpJSON("POST", url, nil, body)
	if err != nil || status < 200 || status >= 300 {
		return tr, false
	}
	if err := json.Unmarshal(data, &tr); err != nil || tr.AccessToken == "" {
		return tr, false
	}
	return tr, true
}

// oauthRefreshForm is the OIDC-style refresh used by xAI (application/x-www-form-urlencoded).
func oauthRefreshForm(tokenURL, refreshToken, clientID string) (tokenResponse, bool) {
	var tr tokenResponse
	if refreshToken == "" {
		return tr, false
	}

	form := strings.NewReader(url.Values{
		"grant_type":    {"refresh_token"},
		"refresh_token": {refreshToken},
		"client_id":     {clientID},
	}.Encode())

	req, err := http.NewRequest("POST", tokenURL, form)
	if err != nil {
		return tr, false
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("Accept", "application/json")

	resp, err := httpClient.Do(req)
	if err != nil {
		return tr, false
	}
	defer resp.Body.Close()

	data, err := io.ReadAll(resp.Body)
	if err != nil || resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return tr, false
	}
	if err := json.Unmarshal(data, &tr); err != nil || tr.AccessToken == "" {
		return tr, false
	}
	return tr, true
}

// ── Claude (Anthropic) ──────────────────────────────────────────────────────

func claudeUsage(token string) (int, []byte, error) {
	return httpJSON("GET", claudeUsageURL, map[string]string{
		"Authorization":  "Bearer " + token,
		"anthropic-beta": "oauth-2025-04-20",
	}, nil)
}

func claudeRefresh(top map[string]json.RawMessage, oauth map[string]any) string {
	tr, ok := oauthRefresh(claudeRefreshURL, str(oauth, "refreshToken"), claudeClientID)
	if !ok {
		return ""
	}

	oauth["accessToken"] = tr.AccessToken
	if tr.RefreshToken != "" {
		oauth["refreshToken"] = tr.RefreshToken
	}
	if tr.ExpiresIn > 0 {
		oauth["expiresAt"] = time.Now().Unix()*1000 + tr.ExpiresIn*1000
	}

	if raw, err := json.Marshal(oauth); err == nil {
		top["claudeAiOauth"] = raw
		if full, err := json.MarshalIndent(top, "", "  "); err == nil {
			_ = atomicWrite(claudePath, full)
		}
	}
	return tr.AccessToken
}

func claudeWindows(data []byte) []window {
	type cw struct {
		Utilization *float64 `json:"utilization"`
		ResetsAt    *string  `json:"resets_at"`
	}
	var usage struct {
		FiveHour *cw `json:"five_hour"`
		SevenDay *cw `json:"seven_day"`
	}
	_ = json.Unmarshal(data, &usage)

	var windows []window
	add := func(label string, w *cw) {
		if w != nil && w.Utilization != nil {
			windows = append(windows, window{
				Label:       label,
				UsedPercent: int(math.Round(*w.Utilization)),
				ResetAt:     w.ResetsAt,
			})
		}
	}
	add("5h", usage.FiveHour)
	add("Weekly", usage.SevenDay)
	return windows
}

func dollars(amountMinor int64, exponent int) string {
	div := math.Pow(10, float64(exponent))
	if div == 0 {
		div = 100
	}
	return fmt.Sprintf("$%.2f", float64(amountMinor)/div)
}

// Extra / overage spend on top of the subscription (only when the user has it
// enabled), from the `spend` block.
func claudeNotes(data []byte) []note {
	var d struct {
		Spend *struct {
			Enabled bool `json:"enabled"`
			Percent *int `json:"percent"`
			Used    *struct {
				AmountMinor int64 `json:"amount_minor"`
				Exponent    int   `json:"exponent"`
			} `json:"used"`
			Limit *struct {
				AmountMinor int64 `json:"amount_minor"`
				Exponent    int   `json:"exponent"`
			} `json:"limit"`
		} `json:"spend"`
	}
	_ = json.Unmarshal(data, &d)

	var notes []note
	if d.Spend != nil && d.Spend.Enabled && d.Spend.Used != nil && d.Spend.Limit != nil {
		value := fmt.Sprintf(
			"%s / %s",
			dollars(d.Spend.Used.AmountMinor, d.Spend.Used.Exponent),
			dollars(d.Spend.Limit.AmountMinor, d.Spend.Limit.Exponent),
		)
		if d.Spend.Percent != nil {
			value = fmt.Sprintf("%s (%d%%)", value, *d.Spend.Percent)
		}
		notes = append(notes, note{Label: "Extra usage", Value: value})
	}
	return notes
}

func claudeProvider() provider {
	p := provider{ID: "claude", Name: "Claude"}

	raw, err := os.ReadFile(claudePath)
	if err != nil {
		p.Reason = ptr("no-credentials")
		return p
	}
	var top map[string]json.RawMessage
	if err := json.Unmarshal(raw, &top); err != nil {
		p.Reason = ptr("no-credentials")
		return p
	}

	oauth := map[string]any{}
	_ = json.Unmarshal(top["claudeAiOauth"], &oauth)
	token := str(oauth, "accessToken")
	if token == "" {
		p.Reason = ptr("no-credentials")
		return p
	}
	if sub := str(oauth, "subscriptionType"); sub != "" {
		p.Plan = ptr(sub)
	}

	// expiresAt is epoch milliseconds; refresh proactively if within a minute.
	if exp, ok := oauth["expiresAt"].(float64); ok && exp < float64(time.Now().Add(time.Minute).UnixMilli()) {
		if t := claudeRefresh(top, oauth); t != "" {
			token = t
		}
	}

	status, data, err := claudeUsage(token)
	if err != nil {
		p.Reason = ptr("network")
		return p
	}
	if status == 401 {
		if t := claudeRefresh(top, oauth); t != "" {
			status, data, err = claudeUsage(t)
		}
		if err != nil || status == 401 {
			p.Reason = ptr("auth")
			return p
		}
	}
	if status < 200 || status >= 300 {
		p.Reason = ptr(fmt.Sprintf("http-%d", status))
		return p
	}

	p.Available = true
	p.Windows = claudeWindows(data)
	p.Notes = claudeNotes(data)
	p.Cost = claudeCost()
	return p
}

// ── Codex (ChatGPT / OpenAI) ────────────────────────────────────────────────

func codexUsage(token, accountID string) (int, []byte, error) {
	headers := map[string]string{
		"Authorization": "Bearer " + token,
		"User-Agent":    "epsilon-ai-usage",
	}
	if accountID != "" {
		headers["chatgpt-account-id"] = accountID
	}
	return httpJSON("GET", codexUsageURL, headers, nil)
}

func codexRefresh(top map[string]json.RawMessage, tokens map[string]any) string {
	tr, ok := oauthRefresh(codexRefreshURL, str(tokens, "refresh_token"), codexClientID)
	if !ok {
		return ""
	}

	tokens["access_token"] = tr.AccessToken
	if tr.RefreshToken != "" {
		tokens["refresh_token"] = tr.RefreshToken
	}
	if tr.IDToken != "" {
		tokens["id_token"] = tr.IDToken
	}

	if raw, err := json.Marshal(tokens); err == nil {
		top["tokens"] = raw
		if lr, err := json.Marshal(time.Now().UTC().Format("2006-01-02T15:04:05.000Z")); err == nil {
			top["last_refresh"] = lr
		}
		if full, err := json.MarshalIndent(top, "", "  "); err == nil {
			_ = atomicWrite(codexPath, full)
		}
	}
	return tr.AccessToken
}

func codexWindows(data []byte) []window {
	type cw struct {
		UsedPercent        *float64 `json:"used_percent"`
		LimitWindowSeconds *int64   `json:"limit_window_seconds"`
		ResetAt            *int64   `json:"reset_at"`
	}
	var usage struct {
		RateLimit *struct {
			PrimaryWindow   *cw `json:"primary_window"`
			SecondaryWindow *cw `json:"secondary_window"`
		} `json:"rate_limit"`
	}
	_ = json.Unmarshal(data, &usage)

	var windows []window
	if usage.RateLimit == nil {
		return windows
	}
	for _, w := range []*cw{usage.RateLimit.PrimaryWindow, usage.RateLimit.SecondaryWindow} {
		if w == nil {
			continue
		}
		used, secs, reset := 0.0, int64(0), int64(0)
		if w.UsedPercent != nil {
			used = *w.UsedPercent
		}
		if w.LimitWindowSeconds != nil {
			secs = *w.LimitWindowSeconds
		}
		if w.ResetAt != nil {
			reset = *w.ResetAt
		}
		windows = append(windows, window{
			Label:       windowLabel(secs),
			UsedPercent: int(math.Round(used)),
			ResetAt:     isoFromEpoch(reset),
		})
	}
	return windows
}

// Manual rate-limit reset credits ("resets" the user can trigger by hand) and
// any prepaid credit balance.
func codexNotes(data []byte) []note {
	var d struct {
		ResetCredits *struct {
			AvailableCount *int `json:"available_count"`
		} `json:"rate_limit_reset_credits"`
		Credits *struct {
			HasCredits bool    `json:"has_credits"`
			Balance    *string `json:"balance"`
		} `json:"credits"`
	}
	_ = json.Unmarshal(data, &d)

	var notes []note
	if d.ResetCredits != nil && d.ResetCredits.AvailableCount != nil {
		notes = append(notes, note{
			Label: "Reset credits",
			Value: fmt.Sprintf("%d", *d.ResetCredits.AvailableCount),
		})
	}
	if d.Credits != nil && d.Credits.HasCredits && d.Credits.Balance != nil {
		notes = append(notes, note{Label: "Credit balance", Value: *d.Credits.Balance})
	}
	return notes
}

func codexProvider() provider {
	p := provider{ID: "codex", Name: "Codex"}

	raw, err := os.ReadFile(codexPath)
	if err != nil {
		p.Reason = ptr("no-credentials")
		return p
	}
	var top map[string]json.RawMessage
	if err := json.Unmarshal(raw, &top); err != nil {
		p.Reason = ptr("no-credentials")
		return p
	}

	tokens := map[string]any{}
	_ = json.Unmarshal(top["tokens"], &tokens)
	token := str(tokens, "access_token")
	accountID := str(tokens, "account_id")
	if token == "" {
		p.Reason = ptr("no-credentials")
		return p
	}

	status, data, err := codexUsage(token, accountID)
	if err != nil {
		p.Reason = ptr("network")
		return p
	}
	if status == 401 {
		if t := codexRefresh(top, tokens); t != "" {
			status, data, err = codexUsage(t, accountID)
		}
		if err != nil || status == 401 {
			p.Reason = ptr("auth")
			return p
		}
	}
	if status < 200 || status >= 300 {
		p.Reason = ptr(fmt.Sprintf("http-%d", status))
		return p
	}

	var meta struct {
		PlanType *string `json:"plan_type"`
	}
	_ = json.Unmarshal(data, &meta)
	p.Plan = meta.PlanType
	p.Available = true
	p.Windows = codexWindows(data)
	p.Notes = codexNotes(data)
	return p
}

// ── Grok (xAI SuperGrok / Grok Build) ───────────────────────────────────────

type grokEntry struct {
	key        string
	scopeKey   string
	clientID   string
	token      string
	refresh    string
	expiresAt  time.Time
	authMode   string
	hasExpiry  bool
}

// pickGrokEntry prefers the OIDC SuperGrok scope (auth.x.ai::<client-id>) over
// any legacy entries. Nested maps are the credential objects.
func pickGrokEntry(top map[string]json.RawMessage) (grokEntry, bool) {
	var fallback *grokEntry

	for scope, raw := range top {
		var m map[string]any
		if json.Unmarshal(raw, &m) != nil {
			continue
		}
		token := str(m, "key")
		if token == "" {
			continue
		}

		e := grokEntry{
			scopeKey: scope,
			token:    token,
			refresh:  str(m, "refresh_token"),
			authMode: str(m, "auth_mode"),
			clientID: str(m, "oidc_client_id"),
		}
		if e.clientID == "" {
			// scope key is "https://auth.x.ai::<client-id>"
			if i := strings.LastIndex(scope, "::"); i >= 0 && i+2 < len(scope) {
				e.clientID = scope[i+2:]
			}
		}
		if exp := str(m, "expires_at"); exp != "" {
			if t, err := time.Parse(time.RFC3339Nano, exp); err == nil {
				e.expiresAt = t
				e.hasExpiry = true
			} else if t, err := time.Parse(time.RFC3339, exp); err == nil {
				e.expiresAt = t
				e.hasExpiry = true
			}
		}

		if strings.HasPrefix(scope, grokOIDCPrefix) {
			return e, true
		}
		if fallback == nil {
			cp := e
			fallback = &cp
		}
	}
	if fallback != nil {
		return *fallback, true
	}
	return grokEntry{}, false
}

func grokRefresh(top map[string]json.RawMessage, e *grokEntry) string {
	if e.clientID == "" || e.refresh == "" {
		return ""
	}

	tr, ok := oauthRefreshForm(grokRefreshURL, e.refresh, e.clientID)
	if !ok {
		return ""
	}

	var entry map[string]any
	_ = json.Unmarshal(top[e.scopeKey], &entry)
	if entry == nil {
		entry = map[string]any{}
	}
	entry["key"] = tr.AccessToken
	if tr.RefreshToken != "" {
		entry["refresh_token"] = tr.RefreshToken
		e.refresh = tr.RefreshToken
	}
	if tr.ExpiresIn > 0 {
		entry["expires_at"] = time.Now().UTC().Add(time.Duration(tr.ExpiresIn) * time.Second).Format(time.RFC3339Nano)
	}

	if raw, err := json.Marshal(entry); err == nil {
		top[e.scopeKey] = raw
		if full, err := json.MarshalIndent(top, "", "  "); err == nil {
			_ = atomicWrite(grokPath, full)
		}
	}

	e.token = tr.AccessToken
	return tr.AccessToken
}

func grokAuthGet(path, token string) (int, []byte, error) {
	return httpJSON("GET", path, map[string]string{
		"Authorization": "Bearer " + token,
		"Accept":        "application/json",
		"User-Agent":    "epsilon-ai-usage",
	}, nil)
}

func grokPlanLabel(tier string) string {
	switch strings.ToLower(tier) {
	case "xpremiumplus", "x_premium_plus", "x-premium-plus":
		return "X Premium+"
	case "xpremium", "x_premium", "x-premium":
		return "X Premium"
	case "supergrok", "super_grok":
		return "SuperGrok"
	case "supergrokheavy", "super_grok_heavy":
		return "SuperGrok Heavy"
	case "":
		return ""
	default:
		return tier
	}
}

func grokWindowsAndNotes(credits, monthly []byte) ([]window, []note) {
	var windows []window
	var notes []note

	// format=credits: weekly (or period) percent + reset end.
	var c struct {
		Config *struct {
			CurrentPeriod *struct {
				Type  string  `json:"type"`
				Start string  `json:"start"`
				End   string  `json:"end"`
			} `json:"currentPeriod"`
			CreditUsagePercent *float64 `json:"creditUsagePercent"`
			OnDemandCap        *struct {
				Val float64 `json:"val"`
			} `json:"onDemandCap"`
			OnDemandUsed *struct {
				Val float64 `json:"val"`
			} `json:"onDemandUsed"`
			PrepaidBalance *struct {
				Val float64 `json:"val"`
			} `json:"prepaidBalance"`
			ProductUsage []struct {
				Product      string   `json:"product"`
				UsagePercent *float64 `json:"usagePercent"`
			} `json:"productUsage"`
			BillingPeriodEnd string `json:"billingPeriodEnd"`
		} `json:"config"`
	}
	_ = json.Unmarshal(credits, &c)

	if c.Config != nil && c.Config.CreditUsagePercent != nil {
		label := "Credits"
		var reset *string
		if p := c.Config.CurrentPeriod; p != nil {
			if p.End != "" {
				reset = ptr(normalizeISO(p.End))
			}
			switch {
			case strings.Contains(strings.ToUpper(p.Type), "WEEK"):
				label = "Weekly"
			case strings.Contains(strings.ToUpper(p.Type), "MONTH"):
				label = "Monthly"
			case strings.Contains(strings.ToUpper(p.Type), "DAY") || strings.Contains(strings.ToUpper(p.Type), "5H") || strings.Contains(strings.ToUpper(p.Type), "HOUR"):
				if p.Start != "" && p.End != "" {
					if s, err1 := time.Parse(time.RFC3339Nano, p.Start); err1 == nil {
						if e, err2 := time.Parse(time.RFC3339Nano, p.End); err2 == nil {
							label = windowLabel(int64(e.Sub(s).Seconds()))
						}
					}
				}
			}
		} else if c.Config.BillingPeriodEnd != "" {
			reset = ptr(normalizeISO(c.Config.BillingPeriodEnd))
		}
		windows = append(windows, window{
			Label:       label,
			UsedPercent: int(math.Round(*c.Config.CreditUsagePercent)),
			ResetAt:     reset,
		})
	}

	// Default billing: monthly used/limit when credits percent is missing, or as a second window.
	var m struct {
		Config *struct {
			MonthlyLimit *struct {
				Val float64 `json:"val"`
			} `json:"monthlyLimit"`
			Used *struct {
				Val float64 `json:"val"`
			} `json:"used"`
			BillingPeriodEnd string `json:"billingPeriodEnd"`
			OnDemandCap      *struct {
				Val float64 `json:"val"`
			} `json:"onDemandCap"`
			OnDemandUsed *struct {
				Val float64 `json:"val"`
			} `json:"onDemandUsed"`
		} `json:"config"`
	}
	_ = json.Unmarshal(monthly, &m)

	if m.Config != nil && m.Config.MonthlyLimit != nil && m.Config.Used != nil && m.Config.MonthlyLimit.Val > 0 {
		pct := int(math.Round(m.Config.Used.Val / m.Config.MonthlyLimit.Val * 100))
		// Avoid a duplicate bar when credits already expressed the same monthly window.
		hasMonthly := false
		for _, w := range windows {
			if w.Label == "Monthly" || w.Label == "Credits" {
				hasMonthly = true
				break
			}
		}
		if !hasMonthly || (len(windows) == 1 && windows[0].Label == "Weekly") {
			var reset *string
			if m.Config.BillingPeriodEnd != "" {
				reset = ptr(normalizeISO(m.Config.BillingPeriodEnd))
			}
			// Only add Monthly if we don't already have a weekly credits window
			// that already covers subscription quota — still useful as absolute units note.
			if len(windows) == 0 {
				windows = append(windows, window{
					Label:       "Monthly",
					UsedPercent: pct,
					ResetAt:     reset,
				})
			}
		}
		notes = append(notes, note{
			Label: "Included",
			Value: fmt.Sprintf("%s / %s",
				fmtGrokAmount(m.Config.Used.Val),
				fmtGrokAmount(m.Config.MonthlyLimit.Val)),
		})
	}

	if c.Config != nil {
		if c.Config.OnDemandCap != nil && c.Config.OnDemandUsed != nil && c.Config.OnDemandCap.Val > 0 {
			notes = append(notes, note{
				Label: "On-demand",
				Value: fmt.Sprintf("%s / %s",
					fmtGrokAmount(c.Config.OnDemandUsed.Val),
					fmtGrokAmount(c.Config.OnDemandCap.Val)),
			})
		}
		if c.Config.PrepaidBalance != nil && c.Config.PrepaidBalance.Val > 0 {
			notes = append(notes, note{
				Label: "Prepaid",
				Value: fmtGrokAmount(c.Config.PrepaidBalance.Val),
			})
		}
		for _, pu := range c.Config.ProductUsage {
			if pu.UsagePercent == nil || pu.Product == "" {
				continue
			}
			// Skip if it duplicates the primary credits percent.
			if c.Config.CreditUsagePercent != nil && *pu.UsagePercent == *c.Config.CreditUsagePercent && len(c.Config.ProductUsage) == 1 {
				continue
			}
			notes = append(notes, note{
				Label: pu.Product,
				Value: fmt.Sprintf("%d%%", int(math.Round(*pu.UsagePercent))),
			})
		}
	}

	return windows, notes
}

func normalizeISO(s string) string {
	if t, err := time.Parse(time.RFC3339Nano, s); err == nil {
		return t.UTC().Format("2006-01-02T15:04:05Z")
	}
	if t, err := time.Parse(time.RFC3339, s); err == nil {
		return t.UTC().Format("2006-01-02T15:04:05Z")
	}
	return s
}

// fmtGrokAmount formats billing amounts. Values from the API are often whole
// credit units (or cents-like integers). Prefer compact integers when clean.
func fmtGrokAmount(v float64) string {
	if v >= 1000 {
		return fmt.Sprintf("%.0f", v)
	}
	if math.Abs(v-math.Round(v)) < 0.05 {
		return fmt.Sprintf("%.0f", math.Round(v))
	}
	return fmt.Sprintf("%.2f", v)
}

func grokProvider() provider {
	p := provider{ID: "grok", Name: "Grok"}

	raw, err := os.ReadFile(grokPath)
	if err != nil {
		p.Reason = ptr("no-credentials")
		return p
	}
	var top map[string]json.RawMessage
	if err := json.Unmarshal(raw, &top); err != nil {
		p.Reason = ptr("no-credentials")
		return p
	}

	entry, ok := pickGrokEntry(top)
	if !ok {
		p.Reason = ptr("no-credentials")
		return p
	}

	token := entry.token
	// Refresh proactively within a minute of expiry.
	if entry.hasExpiry && time.Now().Add(time.Minute).After(entry.expiresAt) {
		if t := grokRefresh(top, &entry); t != "" {
			token = t
		}
	}

	status, userData, err := grokAuthGet(grokUserURL, token)
	if err != nil {
		p.Reason = ptr("network")
		return p
	}
	if status == 401 {
		if t := grokRefresh(top, &entry); t != "" {
			token = t
			status, userData, err = grokAuthGet(grokUserURL, token)
		}
		if err != nil || status == 401 {
			p.Reason = ptr("auth")
			return p
		}
	}
	if status < 200 || status >= 300 {
		p.Reason = ptr(fmt.Sprintf("http-%d", status))
		return p
	}

	var user struct {
		SubscriptionTier  *string `json:"subscriptionTier"`
		HasGrokCodeAccess *bool   `json:"hasGrokCodeAccess"`
	}
	_ = json.Unmarshal(userData, &user)
	if user.SubscriptionTier != nil {
		if label := grokPlanLabel(*user.SubscriptionTier); label != "" {
			p.Plan = ptr(label)
		}
	} else if entry.authMode != "" {
		p.Plan = ptr(entry.authMode)
	}

	statusC, credits, errC := grokAuthGet(grokBillingURL, token)
	statusM, monthly, errM := grokAuthGet(grokBillingRaw, token)
	if (errC != nil && errM != nil) || (statusC >= 400 && statusM >= 400) {
		// Identity worked; billing failed — still show plan with an error note.
		p.Available = true
		p.Notes = []note{{Label: "Billing", Value: "unavailable"}}
		return p
	}
	if errC != nil || statusC < 200 || statusC >= 300 {
		credits = nil
	}
	if errM != nil || statusM < 200 || statusM >= 300 {
		monthly = nil
	}

	windows, notes := grokWindowsAndNotes(credits, monthly)
	if user.HasGrokCodeAccess != nil && !*user.HasGrokCodeAccess {
		notes = append(notes, note{Label: "Grok Code", Value: "no access"})
	}

	p.Available = true
	p.Windows = windows
	p.Notes = notes
	return p
}

// ── Claude local cost/token scan ────────────────────────────────────────────

const (
	costWindowDays     = 7
	scanFileMaxAgeDays = 8
	// The Claude transcript walk is the slowest part of a refresh (~several
	// seconds). Cache the result across process invocations so the 180s bar
	// poll does not rescan every time. Fresh enough for a usage estimate.
	costCacheTTL = 5 * time.Minute
)

// Anthropic API prices per 1M tokens (USD). Subscription usage is flat-rate, so
// this is only an ESTIMATE of what the same tokens would cost on the API. Priced
// by model-tier keyword; unrecognized models fall back to the sonnet tier.
type price struct {
	in, out, cacheWrite, cacheRead float64
}

func priceFor(model string) price {
	m := strings.ToLower(model)
	switch {
	case strings.Contains(m, "opus"):
		return price{15, 75, 18.75, 1.5}
	case strings.Contains(m, "fable"):
		return price{10, 50, 12.5, 1.0}
	case strings.Contains(m, "haiku"):
		return price{0.8, 4, 1.0, 0.08}
	default:
		return price{3, 15, 3.75, 0.30}
	}
}

// modelLabel collapses a raw model id (e.g. "claude-opus-4-8-20260115") to a
// tier name for the per-model breakdown, matching priceFor's buckets. Unknown
// ids keep their raw string so an unrecognized model is visible rather than
// silently folded into the sonnet default.
func modelLabel(model string) string {
	m := strings.ToLower(model)
	switch {
	case strings.Contains(m, "opus"):
		return "Opus"
	case strings.Contains(m, "fable"):
		return "Fable"
	case strings.Contains(m, "sonnet"):
		return "Sonnet"
	case strings.Contains(m, "haiku"):
		return "Haiku"
	default:
		return model
	}
}

type claudeLine struct {
	Type      string `json:"type"`
	Timestamp string `json:"timestamp"`
	RequestID string `json:"requestId"`
	Message   struct {
		ID    string `json:"id"`
		Model string `json:"model"`
		Usage *struct {
			InputTokens   int64 `json:"input_tokens"`
			OutputTokens  int64 `json:"output_tokens"`
			CacheCreation int64 `json:"cache_creation_input_tokens"`
			CacheRead     int64 `json:"cache_read_input_tokens"`
		} `json:"usage"`
	} `json:"message"`
}

func accumulateClaudeLine(line []byte, dayCutoff string, seen map[string]bool, perDay map[string]*dayCost, perModel map[string]*modelCost) {
	var cl claudeLine
	if json.Unmarshal(line, &cl) != nil {
		return
	}
	if cl.Type != "assistant" || cl.Message.Usage == nil {
		return
	}

	key := cl.Message.ID + "|" + cl.RequestID
	if key != "|" {
		if seen[key] {
			return
		}
		seen[key] = true
	}

	t, err := time.Parse(time.RFC3339, cl.Timestamp)
	if err != nil {
		return
	}
	date := t.Local().Format("2006-01-02")
	if date < dayCutoff {
		return
	}

	u := cl.Message.Usage
	p := priceFor(cl.Message.Model)
	tokens := u.InputTokens + u.OutputTokens + u.CacheCreation + u.CacheRead
	usd := (float64(u.InputTokens)*p.in +
		float64(u.OutputTokens)*p.out +
		float64(u.CacheCreation)*p.cacheWrite +
		float64(u.CacheRead)*p.cacheRead) / 1e6

	dc := perDay[date]
	if dc == nil {
		dc = &dayCost{Date: date}
		perDay[date] = dc
	}
	dc.Tokens += tokens
	dc.EstUsd += usd

	label := modelLabel(cl.Message.Model)
	mc := perModel[label]
	if mc == nil {
		mc = &modelCost{Model: label}
		perModel[label] = mc
	}
	mc.Tokens += tokens
	mc.EstUsd += usd
}

func scanClaudeFile(path, dayCutoff string, seen map[string]bool, perDay map[string]*dayCost, perModel map[string]*modelCost) {
	f, err := os.Open(path)
	if err != nil {
		return
	}
	defer f.Close()

	reader := bufio.NewReader(f)
	for {
		// ReadBytes grows to fit lines of any length (transcript lines can be
		// far larger than bufio.Scanner's cap).
		line, err := reader.ReadBytes('\n')
		if len(line) > 0 {
			accumulateClaudeLine(line, dayCutoff, seen, perDay, perModel)
		}
		if err != nil {
			return
		}
	}
}

func costCachePath() string {
	return homePath(".cache/epsilon-ai-usage/claude-cost.json")
}

func loadCostCache() *costSummary {
	path := costCachePath()
	info, err := os.Stat(path)
	if err != nil || time.Since(info.ModTime()) > costCacheTTL {
		return nil
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return nil
	}
	var s costSummary
	if json.Unmarshal(data, &s) != nil {
		return nil
	}
	// Reject a cache written on a previous calendar day so "today" rolls over.
	today := time.Now().Format("2006-01-02")
	if s.Today.Date != "" && s.Today.Date != today {
		return nil
	}
	return &s
}

func saveCostCache(s *costSummary) {
	if s == nil {
		return
	}
	dir := filepath.Dir(costCachePath())
	_ = os.MkdirAll(dir, 0o700)
	data, err := json.Marshal(s)
	if err != nil {
		return
	}
	_ = atomicWrite(costCachePath(), data)
}

// claudeCost aggregates per-day token totals + estimated cost over the last
// costWindowDays from the Claude Code transcripts, deduplicating assistant turns
// by message id + request id. Only recently-touched files are read so the scan
// stays cheap on every refresh. Results are cached on disk for costCacheTTL
// because each bar poll is a fresh process and the walk is multi-second.
func claudeCost() *costSummary {
	if cached := loadCostCache(); cached != nil {
		return cached
	}

	root := homePath(".claude/projects")
	if _, err := os.Stat(root); err != nil {
		return nil
	}

	cutoff := time.Now().AddDate(0, 0, -scanFileMaxAgeDays)
	dayCutoff := time.Now().AddDate(0, 0, -(costWindowDays - 1)).Format("2006-01-02")

	seen := map[string]bool{}
	perDay := map[string]*dayCost{}
	perModel := map[string]*modelCost{}

	_ = filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.HasSuffix(path, ".jsonl") {
			return nil
		}
		if info, err := d.Info(); err != nil || info.ModTime().Before(cutoff) {
			return nil
		}
		scanClaudeFile(path, dayCutoff, seen, perDay, perModel)
		return nil
	})

	if len(perDay) == 0 {
		return nil
	}

	summary := &costSummary{}
	today := time.Now().Format("2006-01-02")
	summary.Today.Date = today
	summary.Week.Date = fmt.Sprintf("%dd", costWindowDays)

	for _, dc := range perDay {
		summary.Days = append(summary.Days, *dc)
		summary.Week.Tokens += dc.Tokens
		summary.Week.EstUsd += dc.EstUsd
		if dc.Date == today {
			summary.Today = *dc
		}
	}
	sort.Slice(summary.Days, func(i, j int) bool {
		return summary.Days[i].Date > summary.Days[j].Date
	})

	for _, mc := range perModel {
		if mc.Tokens == 0 {
			continue
		}
		summary.Models = append(summary.Models, *mc)
	}
	sort.Slice(summary.Models, func(i, j int) bool {
		return summary.Models[i].EstUsd > summary.Models[j].EstUsd
	})
	saveCostCache(summary)
	return summary
}

func main() {
	out := output{
		GeneratedAt: time.Now().UTC().Format("2006-01-02T15:04:05Z"),
		Providers:   []provider{claudeProvider(), codexProvider(), grokProvider()},
	}
	enc := json.NewEncoder(os.Stdout)
	_ = enc.Encode(out)
}
