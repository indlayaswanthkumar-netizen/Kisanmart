"use server";

import { redirect } from "next/navigation";
import { z } from "zod";

import { createSupabaseServerClient } from "@/lib/supabase/server";

export type AuthActionState = {
  error?: string;
  message?: string;
};

const signInSchema = z.object({
  email: z.string().trim().email().max(254),
  password: z.string().min(8).max(128),
});

const signUpSchema = z.object({
  fullName: z.string().trim().min(2).max(100),
  email: z.string().trim().email().max(254),
  password: z.string().min(8).max(128),
});

export async function signInAction(
  _previousState: AuthActionState,
  formData: FormData,
): Promise<AuthActionState> {
  const parsed = signInSchema.safeParse({
    email: formData.get("email"),
    password: formData.get("password"),
  });

  if (!parsed.success) {
    return { error: "Enter a valid email address and password." };
  }

  const supabase = await createSupabaseServerClient();
  if (!supabase) {
    return {
      error:
        "Accounts are not enabled yet. Add the Supabase project URL and publishable key to the app environment.",
    };
  }

  const { error } = await supabase.auth.signInWithPassword(parsed.data);
  if (error) {
    return {
      error: "We couldn’t sign you in. Check your details and try again.",
    };
  }

  redirect("/");
}

export async function signUpAction(
  _previousState: AuthActionState,
  formData: FormData,
): Promise<AuthActionState> {
  const parsed = signUpSchema.safeParse({
    fullName: formData.get("fullName"),
    email: formData.get("email"),
    password: formData.get("password"),
  });

  if (!parsed.success) {
    return {
      error:
        "Enter your name, a valid email address, and a password of at least 8 characters.",
    };
  }

  const supabase = await createSupabaseServerClient();
  if (!supabase) {
    return {
      error:
        "Accounts are not enabled yet. Add the Supabase project URL and publishable key to the app environment.",
    };
  }

  const { data, error } = await supabase.auth.signUp({
    email: parsed.data.email,
    password: parsed.data.password,
    options: {
      data: { full_name: parsed.data.fullName },
    },
  });

  if (error) {
    return {
      error:
        "We couldn’t create your account. Check your details or try again later.",
    };
  }

  if (data.session) {
    redirect("/");
  }

  return {
    message:
      "Your account request is ready. Check your email for the confirmation link before signing in.",
  };
}

export async function signOutAction(): Promise<void> {
  const supabase = await createSupabaseServerClient();
  if (supabase) {
    await supabase.auth.signOut();
  }
  redirect("/login");
}
