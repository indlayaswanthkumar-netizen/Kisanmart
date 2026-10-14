"use client";

import Link from "next/link";
import { Leaf } from "lucide-react";
import { useActionState } from "react";

import {
  signInAction,
  signUpAction,
  type AuthActionState,
} from "@/app/auth/actions";

type AuthFormProps = {
  mode: "login" | "register";
  supabaseConfigured: boolean;
  configurationMessage: string;
};

const initialState: AuthActionState = {};

export function AuthForm({
  mode,
  supabaseConfigured,
  configurationMessage,
}: AuthFormProps) {
  const isRegister = mode === "register";
  const action = isRegister ? signUpAction : signInAction;
  const [state, formAction, pending] = useActionState(action, initialState);

  return (
    <main className="auth-page">
      <aside className="auth-story">
        <Link className="auth-story-brand" href="/" aria-label="KisanMart home">
          <span className="auth-story-mark" aria-hidden="true">
            <Leaf size={23} strokeWidth={2.2} />
          </span>
          <span>
            <span className="auth-story-name">KisanMart</span>
            <span className="auth-story-caption">For every growing season</span>
          </span>
        </Link>
        <div className="auth-story-copy">
          <div className="auth-story-kicker">A better start for your farm</div>
          <h1>Good growing begins with good information.</h1>
          <p>
            KisanMart is being built around the everyday needs of Indian
            growers, with clear product details and room for local farm
            knowledge.
          </p>
        </div>
        <div className="auth-story-foot">
          Phase 1 account access uses email and password. More sign-in options
          depend on provider setup.
        </div>
      </aside>

      <section className="auth-panel-wrap" aria-labelledby="auth-heading">
        <div className="auth-panel">
          <div className="auth-panel-eyebrow">
            {isRegister ? "Create your farmer account" : "Welcome back"}
          </div>
          <h2 id="auth-heading">{isRegister ? "Join KisanMart" : "Sign in"}</h2>
          <p className="auth-panel-intro">
            {isRegister
              ? "Create a farmer account to prepare for the next KisanMart phase."
              : "Sign in to your KisanMart account."}
          </p>

          <form action={formAction} className="auth-form">
            {isRegister && (
              <div className="auth-field">
                <label htmlFor="fullName">Your name</label>
                <input
                  autoComplete="name"
                  id="fullName"
                  name="fullName"
                  maxLength={100}
                  required
                  data-testid="input-full-name"
                />
              </div>
            )}
            <div className="auth-field">
              <label htmlFor="email">Email address</label>
              <input
                autoComplete="email"
                id="email"
                name="email"
                type="email"
                maxLength={254}
                required
                data-testid="input-email"
              />
            </div>
            <div className="auth-field">
              <label htmlFor="password">Password</label>
              <input
                autoComplete={isRegister ? "new-password" : "current-password"}
                id="password"
                name="password"
                type="password"
                minLength={8}
                maxLength={128}
                required
                data-testid="input-password"
              />
            </div>

            {!supabaseConfigured && (
              <div
                className="auth-feedback auth-feedback-warning"
                role="status"
                aria-live="polite"
              >
                {configurationMessage}
              </div>
            )}
            {state.error && (
              <div className="auth-feedback auth-feedback-error" role="alert">
                {state.error}
              </div>
            )}
            {state.message && (
              <div
                className="auth-feedback auth-feedback-success"
                role="status"
                aria-live="polite"
              >
                {state.message}
              </div>
            )}

            <button
              className="auth-submit"
              type="submit"
              disabled={pending || !supabaseConfigured}
              data-testid="button-auth-submit"
            >
              {pending
                ? "Please wait…"
                : isRegister
                  ? "Create farmer account"
                  : "Sign in"}
            </button>
          </form>

          <div className="auth-panel-foot">
            {isRegister ? "Already have an account? " : "New to KisanMart? "}
            <Link href={isRegister ? "/login" : "/register"}>
              {isRegister ? "Sign in" : "Create an account"}
            </Link>
          </div>
          <p className="auth-provider-note">
            New accounts are assigned the farmer role only. Seller approval and
            administrator access cannot be selected during signup. Phone OTP and
            Google sign-in remain disabled until their Supabase providers are
            configured.
          </p>
        </div>
      </section>
    </main>
  );
}
