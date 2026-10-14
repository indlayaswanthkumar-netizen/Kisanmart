import type { Metadata } from "next";

import { AuthForm } from "@/app/auth/AuthForm";
import { getSupabasePublicConfig } from "@/lib/env";

export const metadata: Metadata = {
  title: "Sign in | KisanMart",
  description: "Sign in to KisanMart with your email and password.",
};

export default function LoginPage() {
  const configuration = getSupabasePublicConfig();
  return (
    <AuthForm
      mode="login"
      supabaseConfigured={configuration.configured}
      configurationMessage={configuration.message}
    />
  );
}
