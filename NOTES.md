# Operational notes

Work log for this fork, kept in-repo so nothing depends on a session. Upstream: [12errh/zen-proxy](https://github.com/12errh/zen-proxy).

## Where things run

| Piece | Location |
|---|---|
| Local proxy | `node zen-proxy.mjs`, config `trial-config.json`, `http://127.0.0.1:8787/v1` |
| VPS (Coolify) | `https://zen-proxy.amara57.com` — root is `/v1`, `/` is the dashboard |
| Pi config | `C:\Users\sensei57\.pi\agent\models.json`, provider `zen-proxy` |
| This thread's model | `zen-proxy/deepseek-v4.1-flash-free`, context 250K |

## Credentials

- `PROXY_KEY` — sent by Pi and API clients as `Authorization: Bearer`. Set in Coolify env.
- `DASHBOARD_PASSWORD` — dashboard login and admin routes (`/api/*`, `/v1/models`). Separate secret on purpose.
- Local `trial-config.json` ships with `proxyKey: ""` (open, no auth). Never commit or deploy that file.
- Fixed: `/v1/messages` forwards a client `x-api-key` only when no `proxyKey` is configured; a configured `PROXY_KEY` remains the gate.

## Model capabilities

`models.json` entries under `zen-proxy`, all `input: ["text","image"]`:

```
big-pickle                 reasoning=false  (but it does reason — flag flip offered)
deepseek-v4.1-flash-free   reasoning=true
glm-5.3-flash-free         reasoning=true
mimo-v2.6-flash-free       reasoning=true
```

Vision verified with a 64×64 red/blue split test image. All four answered correctly: `red and blue`, `red blue`, `Left red, right blue.`, `Red and blue.`

Capability flags are read by Pi from `models.json` and cached per session, so after editing it, restart the client before expecting attachments to work.

## Rate limits (429)

Upstream rate limits **per egress IP**. Measured same-second A/B: datacenter IP (Coolify) returned 429 on `mimo-v2.6-flash-free` and `glm-5.3-flash-free`; the residential IP returned 200 on both.

- The fallback chain already absorbs 429s (`glm` 429 answered as `space-bunny-free`).
- Levers, best first: run where the quota is healthy (local machine), use your own Zen key via `ZEN_KEY` / `defaultZenKey`, and order `fallbackModels` with healthy models first.
- IP rotation to dodge the limit was rejected — it evades the upstream terms and is a fragile fight. An explicit opt-in `EGRESS_PROXY` env var, pointed at a network you own, is the honest version.
- Egress wiring issue found: setting `NODE_USE_ENV_PROXY`, `HTTP_PROXY` and `HTTPS_PROXY` inside `zen-proxy.mjs` is too late because Node reads them before module startup. Compose now provides them before launch; the dashboard reports whether proxy routing is active. Verify one client request against Oxylabs statistics after redeploy.

## Rejected or inert ideas

- `#low` / `#high` / `#max` model ids are an OpenCode convention. The proxy silently falls back to the default model on an unknown id, and the upstream ignores `reasoning_effort` (53 / 56 / 48 reasoning tokens for low / none / high).
- Dashboard auth now uses a random opaque session token rather than putting the password in the cookie. The server stores only a digest in memory; sessions expire after 24 hours or on restart.

## Pending

1. ~~Dashboard password → HttpOnly cookie.~~ Done: `/api/login` sets a random `zp_session` token (HttpOnly, SameSite=Strict, Secure on non-loopback), only its digest is stored in memory, sessions expire after 24 hours or restart, and `/api/logout` revokes them. Legacy password-valued cookies are rejected and cleared.
2. ~~`/v1/messages` `x-api-key` bypass.~~ Done: a client key is forwarded only when no `proxyKey` is configured.
3. ~~README section on per-IP rate limits and the `ZEN_KEY` option.~~ Done.
4. ~~Optional `EGRESS_PROXY` env var in `zen-proxy.mjs`.~~ Done and exposed in `compose.yaml` for Coolify.
5. Flip `big-pickle` to `reasoning: true` in `models.json` if its thinking switch is wanted.
