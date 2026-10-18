# Operations

Notes for this fork's local and Coolify deployments. Do not put secrets in this file.

## Deployments

| Environment | Address or config |
|---|---|
| Local | `node zen-proxy.mjs`, config `trial-config.json`, `http://127.0.0.1:8787` |
| Coolify | `https://zen-proxy.amara57.com`; dashboard at `/`, API at `/v1` |
| Pi | `C:\Users\sensei57\.pi\agent\models.json`, provider `zen-proxy` |

The local trial config has no API key. Keep it out of Git and never deploy it.

## Credentials and dashboard sessions

- `PROXY_KEY` authenticates Pi and API clients.
- `DASHBOARD_PASSWORD` unlocks the dashboard. Keep it different from `PROXY_KEY`.
- The dashboard cookie holds a random session token, not the password. The server keeps only the token hash in memory. Sessions last 24 hours and end on logout or server restart.
- `/v1/messages` uses `PROXY_KEY` when configured. It forwards a caller's `x-api-key` only when no proxy key is set.

After changing the dashboard password or upgrading from a password-valued cookie, log in again.

An earlier cookie-auth build shipped `async async function submitAuth()`. That syntax error stopped the dashboard script, so the page stayed blank and its login flow never ran. Current builds load.

## Models and images

The Pi provider lists five models. Four accept text and image; `beam-free` accepts text only.

| Model | Reasoning flag | Input |
|---|---|---|
| `big-pickle` | off | text, image |
| `deepseek-v4.1-flash-free` | on | text, image |
| `glm-5.3-flash-free` | on | text, image |
| `mimo-v2.6-flash-free` | on | text, image |
| `beam-free` | on | text |

Image input was checked with a red-and-blue test image on the four image models. Pi reads model capabilities at startup, so restart Pi after changing its `models.json`.

The OpenCode upstream ignored `reasoning_effort` in our checks. Pi's `#low`, `#high`, and `#max` suffixes fell back to the default model until `deepseek-v4.1-flash-free` was given a `thinkingLevelMap`; with the map, `/thinking` reaches `low` through `max` on that model. `beam-free` is text-only because upstream rejects a conversation containing an image. The `big-pickle` reasoning flag is still off; turn it on only if Pi's thinking controls need it.

## Rate limits and egress proxy

On October 18, 2026, the Coolify data-center IP received `429` for MiMo and GLM. A residential IP received `200` for the same models. This points to an upstream limit based on egress IP.

- `ZEN_KEY` uses your own Zen quota.
- Put responsive models first in `fallbackModels`. The proxy tries the next model after `429` or `5xx` responses.
- Coolify's `EGRESS_PROXY` setting routes upstream requests through that proxy. Compose passes the proxy variables to Node before startup. The dashboard's egress card reports whether routing is enabled.
- The zen-proxy dashboard counts incoming requests. Oxylabs counts outgoing requests through its proxy.

After deploying an egress change, check that the dashboard says `active`, send one request through Pi, then refresh Oxylabs statistics.

## Follow-up

- Decide whether to enable the `big-pickle` reasoning flag in Pi's `models.json`.
