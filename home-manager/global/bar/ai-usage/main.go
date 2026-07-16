// Command epsilon-ai-usage is a provider-agnostic AI usage fetcher for the Astal
// bar's "extras" panel.
//
// It reads the local OAuth credentials that the Claude Code and Codex CLIs
// maintain, queries each provider's usage endpoint, and prints a single
// normalized JSON document to stdout:
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
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net/http"
	"os"
	"path/filepath"
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
)

var (
	httpClient = &http.Client{Timeout: httpTimeout}
	claudePath = homePath(".claude/.credentials.json")
	codexPath  = homePath(".codex/auth.json")
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

type provider struct {
	ID        string   `json:"id"`
	Name      string   `json:"name"`
	Plan      *string  `json:"plan"`
	Available bool     `json:"available"`
	Reason    *string  `json:"reason"`
	Windows   []window `json:"windows"`
	Notes     []note   `json:"notes"`
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

func main() {
	out := output{
		GeneratedAt: time.Now().UTC().Format("2006-01-02T15:04:05Z"),
		Providers:   []provider{claudeProvider(), codexProvider()},
	}
	enc := json.NewEncoder(os.Stdout)
	_ = enc.Encode(out)
}
