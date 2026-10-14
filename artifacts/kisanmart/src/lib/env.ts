import { z } from "zod";

const publicSupabaseEnv = z.object({
  url: z
    .string()
    .url()
    .refine((value) => ["http:", "https:"].includes(new URL(value).protocol)),
  key: z.string().min(1),
});

export type SupabasePublicConfig = z.infer<typeof publicSupabaseEnv>;

export function getSupabasePublicConfig():
  | { configured: true; config: SupabasePublicConfig }
  | { configured: false; message: string } {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  const key =
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY?.trim() ||
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim();

  if (!url || !key) {
    return {
      configured: false,
      message:
        "Supabase is not configured yet. Add the project URL and publishable key to the app environment to enable accounts.",
    };
  }

  const parsed = publicSupabaseEnv.safeParse({ url, key });
  if (!parsed.success) {
    return {
      configured: false,
      message:
        "Supabase settings are invalid. Check the project URL and publishable key in the app environment.",
    };
  }

  return { configured: true, config: parsed.data };
}
