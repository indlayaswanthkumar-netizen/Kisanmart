"use client";

import { createBrowserClient } from "@supabase/ssr";

import { getSupabasePublicConfig } from "@/lib/env";
import type { Database } from "@/types/database";

export function createSupabaseBrowserClient() {
  const result = getSupabasePublicConfig();
  if (!result.configured) {
    throw new Error(result.message);
  }

  return createBrowserClient<Database>(result.config.url, result.config.key);
}
