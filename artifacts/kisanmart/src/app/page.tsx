import StorefrontPage from "@/components/kisanmart/StorefrontPage";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export default async function HomePage() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = supabase ? await supabase.auth.getUser() : { data: { user: null } };

  const fullName =
    typeof user?.user_metadata?.full_name === "string"
      ? user.user_metadata.full_name.slice(0, 32)
      : undefined;

  return <StorefrontPage isSignedIn={Boolean(user)} userName={fullName} />;
}
