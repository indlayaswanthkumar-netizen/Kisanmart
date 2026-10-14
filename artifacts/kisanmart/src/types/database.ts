// This Phase 1 type map covers the profile and starter-catalog surface only.
// Regenerate the full interface after applying the migration; see README.md.
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type AppRole = "farmer" | "seller" | "admin";
export type SellerStatus = "pending" | "approved" | "rejected" | "suspended";
export type ProductStatus =
  | "draft"
  | "pending_review"
  | "published"
  | "rejected"
  | "archived";
export type OrderStatus =
  | "awaiting_payment"
  | "confirmed"
  | "processing"
  | "shipped"
  | "delivered"
  | "cancelled"
  | "return_requested"
  | "returned"
  | "refunded";
export type PaymentStatus =
  | "pending"
  | "authorized"
  | "paid"
  | "failed"
  | "partially_refunded"
  | "refunded";
export type ShipmentStatus =
  | "pending"
  | "packed"
  | "shipped"
  | "delivered"
  | "cancelled";
export type ReviewStatus = "pending" | "published" | "rejected";
export type ContentStatus = "draft" | "published" | "archived";
export type CouponDiscountType = "percentage" | "fixed_amount";

type TableDefinition<
  Row,
  Insert = Partial<Row>,
  Update = Partial<Omit<Row, "id">>,
> = {
  Row: Row;
  Insert: Insert;
  Update: Update;
  Relationships: [];
};

type RequiredInsert<Row, Required extends keyof Row> = Pick<Row, Required> &
  Partial<Omit<Row, Required>>;

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          full_name: string | null;
          phone: string | null;
          locale: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          full_name?: string | null;
          phone?: string | null;
          locale?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          full_name?: string | null;
          phone?: string | null;
          locale?: string;
          updated_at?: string;
        };
        Relationships: [];
      };
      user_roles: TableDefinition<
        {
          id: string;
          user_id: string;
          role: AppRole;
          granted_by: string | null;
          granted_at: string;
        },
        RequiredInsert<
          {
            id: string;
            user_id: string;
            role: AppRole;
            granted_by: string | null;
            granted_at: string;
          },
          "user_id"
        >
      >;
      addresses: TableDefinition<
        {
          id: string;
          user_id: string;
          recipient_name: string;
          phone: string;
          address_line_1: string;
          address_line_2: string | null;
          locality: string | null;
          city: string;
          state: string;
          postal_code: string;
          country_code: "IN";
          delivery_instructions: string | null;
          is_default: boolean;
          created_at: string;
          updated_at: string;
        },
        RequiredInsert<
          {
            id: string;
            user_id: string;
            recipient_name: string;
            phone: string;
            address_line_1: string;
            address_line_2: string | null;
            locality: string | null;
            city: string;
            state: string;
            postal_code: string;
            country_code: "IN";
            delivery_instructions: string | null;
            is_default: boolean;
            created_at: string;
            updated_at: string;
          },
          | "user_id"
          | "recipient_name"
          | "phone"
          | "address_line_1"
          | "city"
          | "state"
          | "postal_code"
        >
      >;
      sellers: TableDefinition<
        {
          id: string;
          user_id: string;
          business_name: string;
          slug: string;
          description: string | null;
          support_email: string | null;
          support_phone: string | null;
          state: string | null;
          approval_status: SellerStatus;
          approved_at: string | null;
          approved_by: string | null;
          moderation_note: string | null;
          created_at: string;
          updated_at: string;
        },
        RequiredInsert<
          {
            id: string;
            user_id: string;
            business_name: string;
            slug: string;
            description: string | null;
            support_email: string | null;
            support_phone: string | null;
            state: string | null;
            approval_status: SellerStatus;
            approved_at: string | null;
            approved_by: string | null;
            moderation_note: string | null;
            created_at: string;
            updated_at: string;
          },
          "user_id" | "business_name" | "slug"
        >
      >;
      categories: TableDefinition<
        {
          id: string;
          parent_id: string | null;
          name: string;
          slug: string;
          description: string | null;
          is_active: boolean;
          sort_order: number;
          created_at: string;
          updated_at: string;
        },
        RequiredInsert<
          {
            id: string;
            parent_id: string | null;
            name: string;
            slug: string;
            description: string | null;
            is_active: boolean;
            sort_order: number;
            created_at: string;
            updated_at: string;
          },
          "name" | "slug"
        >
      >;
      crops: TableDefinition<
        {
          id: string;
          name: string;
          slug: string;
          scientific_name: string | null;
          description: string | null;
          is_published: boolean;
          created_at: string;
          updated_at: string;
        },
        RequiredInsert<
          {
            id: string;
            name: string;
            slug: string;
            scientific_name: string | null;
            description: string | null;
            is_published: boolean;
            created_at: string;
            updated_at: string;
          },
          "name" | "slug"
        >
      >;
      crop_stages: TableDefinition<
        {
          id: string;
          crop_id: string;
          name: string;
          sequence: number;
          description: string | null;
        },
        RequiredInsert<
          {
            id: string;
            crop_id: string;
            name: string;
            sequence: number;
            description: string | null;
          },
          "crop_id" | "name" | "sequence"
        >
      >;
      products: TableDefinition<
        {
          id: string;
          seller_id: string;
          category_id: string | null;
          name: string;
          slug: string;
          brand: string | null;
          short_description: string | null;
          description: string;
          specifications: Json;
          composition: Json;
          safety_information: string | null;
          status: ProductStatus;
          average_rating: number;
          review_count: number;
          moderation_note: string | null;
          published_at: string | null;
          moderated_by: string | null;
          created_at: string;
          updated_at: string;
        },
        RequiredInsert<
          {
            id: string;
            seller_id: string;
            category_id: string | null;
            name: string;
            slug: string;
            brand: string | null;
            short_description: string | null;
            description: string;
            specifications: Json;
            composition: Json;
            safety_information: string | null;
            status: ProductStatus;
            average_rating: number;
            review_count: number;
            moderation_note: string | null;
            published_at: string | null;
            moderated_by: string | null;
            created_at: string;
            updated_at: string;
          },
          "seller_id" | "name" | "slug"
        >
      >;
      product_variants: TableDefinition<
        {
          id: string;
          product_id: string;
          sku: string;
          pack_size: number;
          pack_unit: string;
          price: number;
          currency_code: "INR";
          is_active: boolean;
          created_at: string;
          updated_at: string;
        },
        RequiredInsert<
          {
            id: string;
            product_id: string;
            sku: string;
            pack_size: number;
            pack_unit: string;
            price: number;
            currency_code: "INR";
            is_active: boolean;
            created_at: string;
            updated_at: string;
          },
          "product_id" | "sku" | "pack_size" | "pack_unit" | "price"
        >
      >;
    };
    Views: Record<string, never>;
    Functions: {
      current_user_is_admin: {
        Args: Record<string, never>;
        Returns: boolean;
      };
      current_user_owns_seller: {
        Args: { p_seller_id: string };
        Returns: boolean;
      };
      current_user_is_approved_seller: {
        Args: { p_seller_id: string };
        Returns: boolean;
      };
      admin_grant_role: {
        Args: { p_user_id: string; p_role: AppRole };
        Returns: undefined;
      };
      admin_remove_role: {
        Args: { p_user_id: string; p_role: AppRole };
        Returns: undefined;
      };
      admin_set_seller_status: {
        Args: {
          p_seller_id: string;
          p_status: SellerStatus;
          p_moderation_note?: string | null;
        };
        Returns: undefined;
      };
      admin_set_product_status: {
        Args: {
          p_product_id: string;
          p_status: ProductStatus;
          p_moderation_note?: string | null;
        };
        Returns: undefined;
      };
      admin_set_asset_approval: {
        Args: { p_asset_id: string; p_approved: boolean };
        Returns: undefined;
      };
      admin_set_review_status: {
        Args: { p_review_id: string; p_status: ReviewStatus };
        Returns: undefined;
      };
      admin_set_question_status: {
        Args: { p_question_id: string; p_status: ReviewStatus };
        Returns: undefined;
      };
      admin_set_seller_document_status: {
        Args: { p_document_id: string; p_status: SellerStatus };
        Returns: undefined;
      };
    };
    Enums: {
      app_role: AppRole;
      seller_status: SellerStatus;
      product_status: ProductStatus;
      order_status: OrderStatus;
      payment_status: PaymentStatus;
      shipment_status: ShipmentStatus;
      review_status: ReviewStatus;
      content_status: ContentStatus;
      coupon_discount_type: CouponDiscountType;
    };
    CompositeTypes: Record<string, never>;
  };
}
