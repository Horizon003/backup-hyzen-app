CREATE TABLE IF NOT EXISTS messages(id TEXT PRIMARY KEY, fingerprint TEXT NOT NULL, title TEXT NOT NULL, body TEXT NOT NULL, route TEXT NOT NULL, category TEXT NOT NULL, audience TEXT NOT NULL, provider_id TEXT, state TEXT NOT NULL, created_at INTEGER NOT NULL, error TEXT);
CREATE TABLE IF NOT EXISTS recipients(message_id TEXT NOT NULL, uid TEXT NOT NULL, PRIMARY KEY(message_id,uid));
CREATE INDEX IF NOT EXISTS recipient_uid ON recipients(uid,message_id);
