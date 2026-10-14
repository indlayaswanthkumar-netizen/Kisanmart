import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

import { getSupabasePublicConfig } from "@/lib/env";
import type { Database } from "@/types/database";

export async function createSupabaseServerClient() {
  const result = getSupabasePublicConfig();
  if (!result.configured) {
    return null;
  }

  const cookieStore = await cookies();
  return createServerClient<Database>(result.config.url, result.config.key, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          for (const { name, value, options } of cookiesToSet) {
            cookieStore.set(name, value, options);
          }
        } catch {
          // Server Components cannot write cookies; middleware refreshes sessions.
        }
      },
    },
  });
}
