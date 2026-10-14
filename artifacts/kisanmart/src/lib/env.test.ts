import assert from "node:assert/strict";
import { afterEach, test } from "node:test";

import { getSupabasePublicConfig } from "./env.ts";

const environmentKeys = [
  "NEXT_PUBLIC_SUPABASE_URL",
  "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY",
  "NEXT_PUBLIC_SUPABASE_ANON_KEY",
] as const;

const originalEnvironment = new Map(
  environmentKeys.map((key) => [key, process.env[key]]),
);

afterEach(() => {
  for (const key of environmentKeys) {
    const originalValue = originalEnvironment.get(key);
    if (originalValue === undefined) {
      delete process.env[key];
    } else {
      process.env[key] = originalValue;
    }
  }
});

test("reports missing Supabase settings without throwing", () => {
  delete process.env.NEXT_PUBLIC_SUPABASE_URL;
  delete process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  delete process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  assert.equal(getSupabasePublicConfig().configured, false);
});

test("accepts the publishable key with an HTTP(S) project URL", () => {
  process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY = "sb_publishable_example";

  assert.deepEqual(getSupabasePublicConfig(), {
    configured: true,
    config: {
      url: "https://example.supabase.co",
      key: "sb_publishable_example",
    },
  });
});

test("accepts the legacy anon key name when no publishable key is set", () => {
  process.env.NEXT_PUBLIC_SUPABASE_URL = "http://localhost:54321";
  delete process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "legacy-anon-example";

  assert.equal(getSupabasePublicConfig().configured, true);
});

test("rejects non-HTTP(S) project URLs", () => {
  process.env.NEXT_PUBLIC_SUPABASE_URL = "ftp://example.supabase.co";
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY = "sb_publishable_example";

  assert.equal(getSupabasePublicConfig().configured, false);
});
