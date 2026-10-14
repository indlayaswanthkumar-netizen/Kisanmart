import type { Metadata } from "next";

import { AuthForm } from "@/app/auth/AuthForm";
import { getSupabasePublicConfig } from "@/lib/env";

export const metadata: Metadata = {
  title: "Create an account | KisanMart",
  description: "Create a farmer account for KisanMart.",
};

export default function RegisterPage() {
  const configuration = getSupabasePublicConfig();
  return (
    <AuthForm
      mode="register"
      supabaseConfigured={configuration.configured}
      configurationMessage={configuration.message}
    />
  );
}
