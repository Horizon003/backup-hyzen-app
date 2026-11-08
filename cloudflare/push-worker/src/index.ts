import {
  createRemoteJWKSet,
  importPKCS8,
  jwtVerify,
  SignJWT,
} from "jose";

type Env = {
  FIREBASE_PROJECT_ID: string;
  ADMIN_UID: string;
  SERVICE_ACCOUNT_JSON: string; // Cloudflare Secret; never client-side
  ALLOWED_ORIGIN?: string;
};

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

const firebaseKeys = createRemoteJWKSet(
  new URL("https://www.googleapis.com/service_accounts/v1/metadata/jwk/securetoken@system.gserviceaccount.com"),
);
const TOPIC = "hyzen_announcements_v1";
const MAX_BODY_BYTES = 4096;

function reply(status: number, value: Record<string, unknown>, origin?: string) {
  const headers: Record<string, string> = {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
    "x-content-type-options": "nosniff",
  };
  if (origin) {
    headers["access-control-allow-origin"] = origin;
    headers["vary"] = "Origin";
  }
  return new Response(JSON.stringify(value), { status, headers });
}

async function requireAdmin(request: Request, env: Env): Promise<void> {
  const header = request.headers.get("authorization") || "";
  const match = /^Bearer\s+(.+)$/i.exec(header);
  if (!match) throw new Error("unauthorized");

  // JWT signature, issuer, audience, expiry and algorithm are validated here.
  // Never trust a client-supplied isAdmin field or UID.
  const { payload } = await jwtVerify(match[1], firebaseKeys, {
    audience: env.FIREBASE_PROJECT_ID,
    issuer: `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`,
    algorithms: ["RS256"],
  });
  const now = Math.floor(Date.now() / 1000);
  if (
    !payload.sub || payload.sub !== env.ADMIN_UID ||
    typeof payload.auth_time !== "number" || payload.auth_time > now ||
    typeof payload.iat !== "number" || payload.iat > now ||
    typeof payload.exp !== "number" || payload.exp <= now
  ) throw new Error("forbidden");
}

async function googleAccessToken(env: Env): Promise<string> {
  const service = JSON.parse(env.SERVICE_ACCOUNT_JSON) as ServiceAccount;
  if (
    service.project_id !== env.FIREBASE_PROJECT_ID ||
    !service.client_email || !service.private_key
  ) throw new Error("service account configuration mismatch");

  const now = Math.floor(Date.now() / 1000);
  const key = await importPKCS8(service.private_key, "RS256");
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(service.client_email)
    .setSubject(service.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!response.ok) throw new Error("Google OAuth failed");
  const data = await response.json() as { access_token?: string };
  if (!data.access_token) throw new Error("Google OAuth returned no token");
  return data.access_token;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const requestOrigin = request.headers.get("origin");
    // Allow only the configured GitHub Pages origin for browser requests.
    // Native Flutter Android clients do not send an Origin header.
    if (requestOrigin && requestOrigin !== env.ALLOWED_ORIGIN) {
      return reply(403, { error: "Origin not allowed" });
    }
    const origin = requestOrigin || undefined;
    if (request.method === "OPTIONS") {
      if (!origin) return reply(403, { error: "Origin required" });
      return new Response(null, {
        status: 204,
        headers: {
          "access-control-allow-origin": origin,
          "access-control-allow-methods": "POST, OPTIONS",
          "access-control-allow-headers": "Authorization, Content-Type",
          "access-control-max-age": "600",
          "vary": "Origin",
        },
      });
    }
    const url = new URL(request.url);
    if (url.pathname === "/health" && request.method === "GET") {
      return reply(200, { ok: true, service: "hyzen-push" }, origin);
    }
    if (url.pathname !== "/send" || request.method !== "POST") {
      return reply(404, { error: "Not found" }, origin);
    }
    if (!env.FIREBASE_PROJECT_ID || !env.ADMIN_UID || !env.SERVICE_ACCOUNT_JSON) {
      return reply(503, { error: "Server not configured" }, origin);
    }

    try {
      await requireAdmin(request, env);
    } catch {
      return reply(403, { error: "Administrator authentication required" }, origin);
    }

    try {
      const declared = Number(request.headers.get("content-length") || 0);
      if (declared > MAX_BODY_BYTES) {
        return reply(413, { error: "Message too large" }, origin);
      }
      const raw = await request.text();
      if (new TextEncoder().encode(raw).length > MAX_BODY_BYTES) {
        return reply(413, { error: "Message too large" }, origin);
      }
      const payload = JSON.parse(raw) as Record<string, unknown>;
      const title = typeof payload.title === "string" ? payload.title.trim() : "";
      const body = typeof payload.body === "string" ? payload.body.trim() : "";
      // Phase 1 intentionally allows only public, all-students messages.
      if (payload.audience !== "all" ||
        !title || !body || title.length > 100 || body.length > 450) {
        return reply(400, { error: "Invalid title, message or audience" }, origin);
      }
      const accessToken = await googleAccessToken(env);
      const result = await fetch(
        `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(env.FIREBASE_PROJECT_ID)}/messages:send`,
        {
          method: "POST",
          headers: {
            "authorization": `Bearer ${accessToken}`,
            "content-type": "application/json",
          },
          body: JSON.stringify({
            message: {
              topic: TOPIC,
              notification: { title, body },
              data: { type: "announcement", route: "/notifications" },
              android: { priority: "high" },
            },
          }),
        },
      );
      if (!result.ok) {
        // Never echo upstream credentials or token-bearing error payloads.
        return reply(502, { error: "FCM rejected the send request" }, origin);
      }
      return reply(200, { ok: true, audience: "all" }, origin);
    } catch {
      return reply(500, { error: "Unable to send notification" }, origin);
    }
  },
};
