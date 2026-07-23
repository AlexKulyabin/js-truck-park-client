--
-- PostgreSQL database dump
--

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.4

-- Started on 2026-07-23 20:04:46 MSK

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 136 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS "public";


--
-- TOC entry 4971 (class 0 OID 0)
-- Dependencies: 136
-- Name: SCHEMA "public"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA "public" IS 'standard public schema';

-- The hosted project keeps PostGIS and pg_trgm in public. Installing them
-- explicitly makes this baseline reproducible in a fresh local Supabase DB.
CREATE EXTENSION IF NOT EXISTS "postgis" WITH SCHEMA "public";
CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA "public";


--
-- TOC entry 2093 (class 1247 OID 45928)
-- Name: parking_rejection_reason; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE "public"."parking_rejection_reason" AS ENUM (
    'duplicate',
    'incomplete_data',
    'not_meeting_requirements'
);


--
-- TOC entry 2087 (class 1247 OID 45726)
-- Name: parking_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE "public"."parking_status" AS ENUM (
    'pending',
    'approved',
    'rejected'
);


--
-- TOC entry 2090 (class 1247 OID 45742)
-- Name: user_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE "public"."user_status" AS ENUM (
    'pending',
    'approved',
    'rejected'
);


--
-- TOC entry 476 (class 1255 OID 46428)
-- Name: aggregate_parking_stats_after(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."aggregate_parking_stats_after"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    t_id UUID;
BEGIN
    t_id := COALESCE(NEW.parking_id, OLD.parking_id);

    UPDATE public.parkings
    SET
        rating = ROUND(CAST(COALESCE((SELECT AVG(average_score) FROM public.reviews WHERE parking_id = t_id AND average_score > 0), 4.0) AS NUMERIC), 1),
        reviews_count = (SELECT COUNT(*) FROM public.reviews WHERE parking_id = t_id AND average_score > 0),
        -- Конвертируем результат в INT, так как в базе тип int4
        stars_1 = (SELECT COUNT(*) FROM public.reviews WHERE parking_id = t_id AND ROUND(average_score) = 1 AND average_score > 0)::INT,
        stars_2 = (SELECT COUNT(*) FROM public.reviews WHERE parking_id = t_id AND ROUND(average_score) = 2 AND average_score > 0)::INT,
        stars_3 = (SELECT COUNT(*) FROM public.reviews WHERE parking_id = t_id AND ROUND(average_score) = 3 AND average_score > 0)::INT,
        stars_4 = (SELECT COUNT(*) FROM public.reviews WHERE parking_id = t_id AND ROUND(average_score) = 4 AND average_score > 0)::INT,
        stars_5 = (SELECT COUNT(*) FROM public.reviews WHERE parking_id = t_id AND ROUND(average_score) = 5 AND average_score > 0)::INT
    WHERE id = t_id;

    RETURN NULL;
END;
$$;


--
-- TOC entry 791 (class 1255 OID 45474)
-- Name: delete_user_account(boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."delete_user_account"("confirm" boolean DEFAULT true) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Нам не важно, что пришло в "confirm", мы просто удаляем юзера, который прислал токен
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;


--
-- TOC entry 1102 (class 1255 OID 46830)
-- Name: generate_referral_code(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."generate_referral_code"() RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Исключены похожие символы (0, O, 1, I)
  result TEXT := '';
  i INTEGER := 0;
BEGIN
  FOR i IN 1..8 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
  END LOOP;
  RETURN result;
END;
$$;


--
-- TOC entry 847 (class 1255 OID 46579)
-- Name: get_filtered_parkings(double precision, double precision, double precision, double precision, double precision, double precision, double precision, integer, integer, boolean, boolean, boolean, boolean, boolean, boolean, boolean, double precision, "text"); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."get_filtered_parkings"("center_lat" double precision, "center_lng" double precision, "radius_meters" double precision, "min_lat" double precision, "max_lat" double precision, "min_lng" double precision, "max_lng" double precision, "min_capacity" integer, "max_capacity" integer, "need_gas" boolean, "need_shower" boolean, "need_laundry" boolean, "need_hotel" boolean, "need_shop" boolean, "need_recreation" boolean, "is_filter_active" boolean, "zoom_level" double precision, "search_query" "text" DEFAULT NULL::"text") RETURNS SETOF json
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  grid_size FLOAT8;
  has_search BOOLEAN;
BEGIN
  has_search := (search_query IS NOT NULL AND search_query <> '');

  grid_size := CASE
    WHEN zoom_level < 4 THEN 10.0
    WHEN zoom_level < 6 THEN 5.0
    WHEN zoom_level < 8 THEN 1.5
    WHEN zoom_level < 10 THEN 0.5
    WHEN zoom_level < 11.0 THEN 0.05
    ELSE 0
  END;

  RETURN QUERY
  WITH raw_data AS (
    SELECT * FROM public.parkings
    WHERE
      -- 1. ГЛАВНОЕ ИЗМЕНЕНИЕ: Фильтр по статусу
      -- Показываем только 'approved', ЕСЛИ пользователь не админ.
      -- Если зашел админ (is_admin() = true), он видит ВСЁ.
      (status = 'approved'::parking_status OR is_admin())

      -- 2. ТЕКСТОВЫЙ ПОИСК
      AND (NOT has_search OR address_lower LIKE '%' || LOWER(search_query) || '%')

      -- 3. ГЕО-ФИЛЬТР
      AND (
        CASE
          WHEN has_search AND NOT (is_filter_active AND radius_meters > 0) THEN TRUE
          WHEN (is_filter_active AND radius_meters > 0) THEN
            (6371000 * acos(LEAST(GREATEST(cos(radians(center_lat)) * cos(radians(latitude)) * cos(radians(longitude) - radians(center_lng)) + sin(radians(center_lat)) * sin(radians(latitude)), -1.0), 1.0))) <= radius_meters
          ELSE (latitude >= min_lat AND latitude <= max_lat AND longitude >= min_lng AND longitude <= max_lng)
        END
      )

      -- 4. ФИЛЬТР УСЛУГ
      AND (
        CASE
          WHEN is_filter_active THEN (
            (COALESCE(total_spaces, 0) >= COALESCE(min_capacity, 0) AND COALESCE(total_spaces, 0) <= COALESCE(max_capacity, 10000))
            AND (need_gas IS NOT TRUE OR has_gas_station IS TRUE)
            AND (need_shower IS NOT TRUE OR has_shower IS TRUE)
            AND (need_laundry IS NOT TRUE OR has_laundry IS TRUE)
            AND (need_hotel IS NOT TRUE OR has_hotel IS TRUE)
            AND (need_shop IS NOT TRUE OR has_shop IS TRUE)
            AND (need_recreation IS NOT TRUE OR has_recreation_area IS TRUE)
          )
          ELSE TRUE
        END
      )
  ),
  grouping AS (
    SELECT
      CASE WHEN grid_size > 0 THEN floor(latitude / grid_size)::text || '_' || floor(longitude / grid_size)::text ELSE id::text END as bucket_id,
      AVG(latitude) as lat, AVG(longitude) as lng,
      COUNT(*)::INT as points_count,
      MAX(id::text) as single_id, MAX(address) as single_address, MAX(rating) as single_rating
    FROM raw_data
    GROUP BY bucket_id
  )
  SELECT row_to_json(out) FROM (
    SELECT
      CASE WHEN points_count > 1 THEN 'c_' || bucket_id ELSE single_id END as id,
      lat, lng, lat as latitude, lng as longitude,
      points_count as count, (grid_size > 0) as is_cluster,
      CASE WHEN points_count = 1 THEN single_address ELSE NULL END as address,
      CASE WHEN points_count = 1 THEN single_rating ELSE NULL END as rating
    FROM grouping
  ) out;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = "heap";

--
-- TOC entry 390 (class 1259 OID 25312)
-- Name: parkings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."parkings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "address" "text",
    "latitude" double precision,
    "longitude" double precision,
    "parking_type" "text",
    "total_spaces" integer,
    "price" numeric,
    "is_free" boolean DEFAULT false NOT NULL,
    "has_gas_station" boolean DEFAULT false NOT NULL,
    "has_shower" boolean DEFAULT false NOT NULL,
    "has_laundry" boolean DEFAULT false NOT NULL,
    "has_hotel" boolean DEFAULT false NOT NULL,
    "has_shop" boolean DEFAULT false NOT NULL,
    "has_recreation_area" boolean DEFAULT false NOT NULL,
    "rating" numeric DEFAULT 4.0,
    "stars_1" integer DEFAULT 0 NOT NULL,
    "stars_2" integer DEFAULT 0 NOT NULL,
    "stars_3" integer DEFAULT 0 NOT NULL,
    "stars_4" integer DEFAULT 0 NOT NULL,
    "stars_5" integer DEFAULT 0 NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "address_lower" "text",
    "status" "public"."parking_status" DEFAULT 'pending'::"public"."parking_status" NOT NULL,
    "photos" "text"[],
    "is_active" boolean DEFAULT true,
    "admin_comment" "text",
    "location" "public"."geography"(Point,4326) GENERATED ALWAYS AS (("public"."st_setsrid"("public"."st_makepoint"("longitude", "latitude"), 4326))::"public"."geography") STORED,
    "reviews_count" bigint DEFAULT 0,
    "rejection_reason" "public"."parking_rejection_reason"
);


--
-- TOC entry 700 (class 1255 OID 27847)
-- Name: get_parkings_by_location(double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."get_parkings_by_location"("lat" double precision, "lng" double precision, "radius_meters" double precision) RETURNS SETOF "public"."parkings"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  SELECT *
  FROM parkings
  WHERE ST_DWithin(
    location,
    ST_SetSRID(ST_Point(lng, lat), 4326)::geography,
    radius_meters
  )
  AND status = 'approved'
  AND is_active = true;
$$;


--
-- TOC entry 687 (class 1255 OID 27879)
-- Name: get_parkings_by_viewport(double precision, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."get_parkings_by_viewport"("min_lng" double precision, "min_lat" double precision, "max_lng" double precision, "max_lat" double precision, "zoom_level" double precision) RETURNS TABLE("lat" double precision, "lng" double precision, "count" integer, "id" "uuid", "is_cluster" boolean)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- ТЕПЕРЬ КЛАСТЕРЫ ТОЛЬКО ДО ЗУМА 8 (Масштаб страны)
  IF zoom_level < 8 THEN
    RETURN QUERY
    SELECT
      ST_Y(ST_Centroid(ST_Collect(location::geometry))) AS lat,
      ST_X(ST_Centroid(ST_Collect(location::geometry))) AS lng,
      COUNT(*)::integer AS count,
      NULL::uuid AS id,
      true AS is_cluster
    FROM parkings
    WHERE location && ST_MakeEnvelope(min_lng, min_lat, max_lng, max_lat, 4326)
      AND status = 'approved' AND is_active = true
    GROUP BY ST_SnapToGrid(location::geometry,
      CASE
        WHEN zoom_level < 3 THEN 10.0
        WHEN zoom_level < 5 THEN 5.0
        WHEN zoom_level < 7 THEN 1.0
        ELSE 0.1 -- Сетка для зума 7-8
      END
    );

  -- ТЕПЕРЬ МАРКЕРЫ ПОЯВЛЯЮТСЯ УЖЕ НА ЗУМЕ 8 (Масштаб области)
  ELSE
    RETURN QUERY
    SELECT
      latitude AS lat,
      longitude AS lng,
      1 AS count,
      parkings.id,
      false AS is_cluster
    FROM parkings
    WHERE location && ST_MakeEnvelope(min_lng, min_lat, max_lng, max_lat, 4326)
      AND status = 'approved' AND is_active = true
    LIMIT 500; -- Оставляем лимит, чтобы не перегружать телефон
  END IF;
END;
$$;


--
-- TOC entry 922 (class 1255 OID 45774)
-- Name: handle_new_auth_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."handle_new_auth_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  -- Вставляем запись в таблицу профилей
  INSERT INTO public.users (
    id,
    full_name,
    avatar_url,
    status,
    is_admin,
    referral_code,
    phone
  )
  VALUES (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url',
    -- Статус: если есть телефон (SMS), то approved, иначе (Email) - pending
    (CASE WHEN new.phone IS NOT NULL AND new.phone <> '' THEN 'approved'::user_status ELSE 'pending'::user_status END),
    false,
    upper(substring(md5(random()::text) from 1 for 8)), -- Генерация реф. кода
    new.phone
  )
  ON CONFLICT (id) DO UPDATE SET
    phone = EXCLUDED.phone,
    status = EXCLUDED.status;

  RETURN NEW;

EXCEPTION WHEN OTHERS THEN
  -- Если что-то пошло не так, мы просто разрешаем Supabase создать юзера,
  -- чтобы не блокировать SMS и вход. Ошибку можно будет увидеть в логах.
  RETURN NEW;
END;
$$;


--
-- TOC entry 1142 (class 1255 OID 41756)
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  -- Вставляем данные в твою таблицу public.users
  -- В кавычках "users", на случай если Postgres капризничает
  insert into public.users (id, phone)
  values (new.id, new.phone);
  return new;
end;
$$;


--
-- TOC entry 494 (class 1255 OID 46427)
-- Name: handle_review_score_before(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."handle_review_score_before"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_sum FLOAT8 := 0;
    v_count INT := 0;
BEGIN
    -- Считаем сумму только тех полей, которые > 0
    IF COALESCE(NEW.rating_impression, 0) > 0 THEN v_sum := v_sum + NEW.rating_impression; v_count := v_count + 1; END IF;
    IF COALESCE(NEW.rating_arrival, 0) > 0 THEN v_sum := v_sum + NEW.rating_arrival; v_count := v_count + 1; END IF;
    IF COALESCE(NEW.rating_security, 0) > 0 THEN v_sum := v_sum + NEW.rating_security; v_count := v_count + 1; END IF;
    IF COALESCE(NEW.rating_infrastructure, 0) > 0 THEN v_sum := v_sum + NEW.rating_infrastructure; v_count := v_count + 1; END IF;
    IF COALESCE(NEW.rating_comfort, 0) > 0 THEN v_sum := v_sum + NEW.rating_comfort; v_count := v_count + 1; END IF;

    -- Записываем среднее в NEW.average_score
    IF v_count > 0 THEN
        NEW.average_score := v_sum / v_count;
    ELSE
        NEW.average_score := 0;
    END IF;

    RETURN NEW;
END;
$$;


--
-- TOC entry 514 (class 1255 OID 45357)
-- Name: initialize_parking_rating(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."initialize_parking_rating"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Принудительно ставим 4.0 при создании
    NEW.rating := 4.0;
    NEW.reviews_count := 0;
    RETURN NEW;
END;
$$;


--
-- TOC entry 1213 (class 1255 OID 45963)
-- Name: is_admin(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."is_admin"() RETURNS boolean
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  SELECT COALESCE(is_admin, FALSE)
  FROM public.users
  WHERE id = auth.uid();
$$;


--
-- TOC entry 782 (class 1255 OID 46859)
-- Name: process_referral("text", "uuid", "text"); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."process_referral"("p_ref_code" "text", "p_referee_id" "uuid", "p_device_id" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_referrer_id UUID;
    v_result JSONB;
BEGIN
    -- 1. Ищем владельца реферального кода
    SELECT id INTO v_referrer_id FROM public.users WHERE referral_code = p_ref_code LIMIT 1;

    -- 2. ПРОВЕРКИ ЗАЩИТЫ
    -- Проверка: существует ли такой код?
    IF v_referrer_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Invalid referral code');
    END IF;

    -- Проверка: не приглашает ли юзер сам себя?
    IF v_referrer_id = p_referee_id THEN
        RETURN jsonb_build_object('success', false, 'message', 'You cannot refer yourself');
    END IF;

    -- Проверка: не использовалось ли это устройство уже для получения бонуса?
    IF EXISTS (SELECT 1 FROM public.referral_stats WHERE device_id = p_device_id) THEN
        RETURN jsonb_build_object('success', false, 'message', 'Device already used for referral');
    END IF;

    -- 3. ЕСЛИ ВСЁ ОК — ПРИВЯЗЫВАЕМ
    -- Обновляем профиль пользователя
    UPDATE public.users
    SET referred_by_id = v_referrer_id
    WHERE id = p_referee_id;

    -- Записываем в лог статистики
    INSERT INTO public.referral_stats (referrer_id, referee_id, device_id)
    VALUES (v_referrer_id, p_referee_id, p_device_id);

    RETURN jsonb_build_object('success', true, 'message', 'Referral applied successfully');

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'message', SQLERRM);
END;
$$;


--
-- TOC entry 540 (class 1255 OID 45435)
-- Name: sync_user_data_to_auth(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "public"."sync_user_data_to_auth"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Используем вложенный блок BEGIN/EXCEPTION, чтобы ошибка здесь не ломала основной UPDATE
  BEGIN
    UPDATE auth.users
    SET raw_user_meta_data =
      COALESCE(raw_user_meta_data, '{}'::jsonb) ||
      jsonb_build_object(
        'display_name', NEW.full_name,
        'avatar_url', NEW.avatar_url
      )
    WHERE id = NEW.id;
  EXCEPTION WHEN OTHERS THEN
    -- Если произошла ошибка (например, нет прав), просто продолжаем
    RETURN NEW;
  END;

  RETURN NEW;
END;
$$;


--
-- TOC entry 401 (class 1259 OID 28989)
-- Name: favorites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."favorites" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_id" "uuid",
    "parking_id" "uuid"
);


--
-- TOC entry 402 (class 1259 OID 28992)
-- Name: favorites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."favorites" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."favorites_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 403 (class 1259 OID 41851)
-- Name: parking_photos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."parking_photos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "url" "text" NOT NULL,
    "parking_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "review_id" bigint
);


--
-- TOC entry 409 (class 1259 OID 46831)
-- Name: referral_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."referral_stats" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "referrer_id" "uuid",
    "referee_id" "uuid",
    "device_id" "text",
    "ip_address" "text",
    "status" "text" DEFAULT 'registered'::"text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


--
-- TOC entry 394 (class 1259 OID 26723)
-- Name: reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reports" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "parking_id" "uuid",
    "user_id" "uuid",
    "category" "text",
    "comment" "text",
    "status" "text" DEFAULT 'penging'::"text",
    "report" "text"
);


--
-- TOC entry 395 (class 1259 OID 26726)
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."reports" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."reports_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 405 (class 1259 OID 44154)
-- Name: reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."reviews" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_id" "uuid",
    "parking_id" "uuid" NOT NULL,
    "comment" "text",
    "rating_impression" smallint NOT NULL,
    "rating_arrival" smallint NOT NULL,
    "rating_security" smallint NOT NULL,
    "rating_infrastructure" smallint NOT NULL,
    "rating_comfort" smallint NOT NULL,
    "average_score" real
);


--
-- TOC entry 404 (class 1259 OID 44153)
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE "public"."reviews" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."reviews_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 393 (class 1259 OID 25572)
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "public"."users" (
    "id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "full_name" "text",
    "avatar_url" "text",
    "phone" "text",
    "is_premium" boolean DEFAULT false,
    "referral_code" "text",
    "theme" "text" DEFAULT 'light'::"text",
    "updated_at" timestamp without time zone,
    "status" "public"."user_status" DEFAULT 'pending'::"public"."user_status",
    "is_admin" boolean DEFAULT false,
    "referred_by_id" "uuid",
    "last_device_id" "text"
);


--
-- TOC entry 410 (class 1259 OID 47011)
-- Name: view_full_parking_details; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW "public"."view_full_parking_details" WITH ("security_invoker"='true') AS
 SELECT "p"."id",
    "p"."created_at",
    "p"."address",
    "p"."latitude",
    "p"."longitude",
    "p"."parking_type",
    "p"."total_spaces",
    "p"."price",
    "p"."is_free",
    "p"."has_gas_station",
    "p"."has_shower",
    "p"."has_laundry",
    "p"."has_hotel",
    "p"."has_shop",
    "p"."has_recreation_area",
    "p"."rating",
    "p"."stars_1",
    "p"."stars_2",
    "p"."stars_3",
    "p"."stars_4",
    "p"."stars_5",
    "p"."created_by",
    "p"."updated_at",
    "p"."address_lower",
    "p"."status",
    "p"."photos",
    "p"."is_active",
    "p"."admin_comment",
    "p"."location",
    "p"."reviews_count",
    "p"."rejection_reason",
    ( SELECT "json_agg"("json_build_object"('url', "parking_photos"."url", 'photo_date', COALESCE("to_char"("parking_photos"."created_at", 'DD.MM.YYYY'::"text"), ''::"text"))) AS "json_agg"
           FROM "public"."parking_photos"
          WHERE ("parking_photos"."parking_id" = "p"."id")) AS "all_photos",
    ( SELECT ("count"(*))::integer AS "count"
           FROM "public"."parking_photos"
          WHERE ("parking_photos"."parking_id" = "p"."id")) AS "photos_count",
    (EXISTS ( SELECT 1
           FROM "public"."favorites"
          WHERE (("favorites"."parking_id" = "p"."id") AND ("favorites"."user_id" = "auth"."uid"())))) AS "is_favorited",
    "u"."full_name" AS "creator_name",
    "u"."avatar_url" AS "creator_avatar"
   FROM ("public"."parkings" "p"
     LEFT JOIN "public"."users" "u" ON (("p"."created_by" = "u"."id")))
  WHERE (("p"."status" = 'approved'::"public"."parking_status") OR "public"."is_admin"());


--
-- TOC entry 408 (class 1259 OID 46681)
-- Name: view_reports_detailed; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW "public"."view_reports_detailed" WITH ("security_invoker"='true') AS
 SELECT "r"."id" AS "report_id",
    "r"."user_id" AS "reporter_id",
    "r"."created_at" AS "report_date",
    "r"."report" AS "report_type",
    "r"."comment" AS "report_comment",
    "r"."parking_id",
    "p"."address" AS "parking_address",
    ( SELECT "jsonb_agg"("parking_photos"."url") AS "jsonb_agg"
           FROM "public"."parking_photos"
          WHERE (("parking_photos"."parking_id" = "r"."parking_id") AND ("parking_photos"."review_id" IS NULL))) AS "parking_photos",
    ( SELECT ("count"(*))::integer AS "count"
           FROM "public"."parking_photos"
          WHERE (("parking_photos"."parking_id" = "r"."parking_id") AND ("parking_photos"."review_id" IS NULL))) AS "photos_count",
    "u"."full_name" AS "reporter_name",
    "u"."phone" AS "reporter_phone"
   FROM (("public"."reports" "r"
     LEFT JOIN "public"."parkings" "p" ON (("r"."parking_id" = "p"."id")))
     LEFT JOIN "public"."users" "u" ON (("r"."user_id" = "u"."id")));


--
-- TOC entry 406 (class 1259 OID 46671)
-- Name: view_reviews_with_users; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW "public"."view_reviews_with_users" WITH ("security_invoker"='true') AS
 SELECT "r"."id",
    "r"."created_at",
    "r"."user_id",
    "r"."parking_id",
    "r"."comment",
    "r"."rating_impression",
    "r"."rating_arrival",
    "r"."rating_security",
    "r"."rating_infrastructure",
    "r"."rating_comfort",
    "r"."average_score",
    "p"."address" AS "parking_address",
    "u"."full_name" AS "author_name",
    "u"."avatar_url" AS "author_avatar",
    ( SELECT "jsonb_agg"("ph"."url") AS "jsonb_agg"
           FROM "public"."parking_photos" "ph"
          WHERE ("ph"."review_id" = "r"."id")) AS "review_photos"
   FROM (("public"."reviews" "r"
     LEFT JOIN "public"."users" "u" ON (("r"."user_id" = "u"."id")))
     LEFT JOIN "public"."parkings" "p" ON (("r"."parking_id" = "p"."id")));


--
-- TOC entry 407 (class 1259 OID 46676)
-- Name: view_user_favorites; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW "public"."view_user_favorites" WITH ("security_invoker"='true') AS
 SELECT "f"."id" AS "favorite_record_id",
    "f"."user_id",
    "p"."id" AS "parking_id",
    COALESCE("p"."address", 'Адрес не указан'::"text") AS "address",
    COALESCE("p"."latitude", (0.0)::double precision) AS "latitude",
    COALESCE("p"."longitude", (0.0)::double precision) AS "longitude",
    COALESCE("p"."rating", 0.0) AS "rating",
    COALESCE("p"."reviews_count", (0)::bigint) AS "reviews_count",
    ( SELECT "jsonb_agg"("parking_photos"."url") AS "jsonb_agg"
           FROM "public"."parking_photos"
          WHERE ("parking_photos"."parking_id" = "p"."id")) AS "photos"
   FROM ("public"."favorites" "f"
     JOIN "public"."parkings" "p" ON (("f"."parking_id" = "p"."id")));


--
-- TOC entry 4724 (class 2606 OID 28998)
-- Name: favorites favorites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_pkey" PRIMARY KEY ("id");


--
-- TOC entry 4731 (class 2606 OID 41859)
-- Name: parking_photos parking_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."parking_photos"
    ADD CONSTRAINT "parking_photos_pkey" PRIMARY KEY ("id");


--
-- TOC entry 4716 (class 2606 OID 25330)
-- Name: parkings parkings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."parkings"
    ADD CONSTRAINT "parkings_pkey" PRIMARY KEY ("id");


--
-- TOC entry 4738 (class 2606 OID 46840)
-- Name: referral_stats referral_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."referral_stats"
    ADD CONSTRAINT "referral_stats_pkey" PRIMARY KEY ("id");


--
-- TOC entry 4720 (class 2606 OID 26736)
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reports"
    ADD CONSTRAINT "reports_pkey" PRIMARY KEY ("id");


--
-- TOC entry 4734 (class 2606 OID 44166)
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_pkey" PRIMARY KEY ("id");


--
-- TOC entry 4740 (class 2606 OID 46844)
-- Name: referral_stats unique_device_referral; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."referral_stats"
    ADD CONSTRAINT "unique_device_referral" UNIQUE ("device_id");


--
-- TOC entry 4742 (class 2606 OID 46842)
-- Name: referral_stats unique_referral; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."referral_stats"
    ADD CONSTRAINT "unique_referral" UNIQUE ("referee_id");


--
-- TOC entry 4727 (class 2606 OID 29020)
-- Name: favorites unique_user_parking_favorite; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "unique_user_parking_favorite" UNIQUE ("user_id", "parking_id");


--
-- TOC entry 4736 (class 2606 OID 47484)
-- Name: reviews unique_user_parking_review; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "unique_user_parking_review" UNIQUE ("user_id", "parking_id");


--
-- TOC entry 4718 (class 2606 OID 25580)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");


--
-- TOC entry 4725 (class 1259 OID 46214)
-- Name: idx_favorites_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "idx_favorites_user_id" ON "public"."favorites" USING "btree" ("user_id");


--
-- TOC entry 4712 (class 1259 OID 46129)
-- Name: idx_parkings_address_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "idx_parkings_address_trgm" ON "public"."parkings" USING "gin" ("address_lower" "public"."gin_trgm_ops");


--
-- TOC entry 4713 (class 1259 OID 46217)
-- Name: idx_parkings_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "idx_parkings_status" ON "public"."parkings" USING "btree" ("status");


--
-- TOC entry 4728 (class 1259 OID 46215)
-- Name: idx_photos_parking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "idx_photos_parking_id" ON "public"."parking_photos" USING "btree" ("parking_id");


--
-- TOC entry 4729 (class 1259 OID 46216)
-- Name: idx_photos_review_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "idx_photos_review_id" ON "public"."parking_photos" USING "btree" ("review_id");


--
-- TOC entry 4732 (class 1259 OID 46213)
-- Name: idx_reviews_parking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "idx_reviews_parking_id" ON "public"."reviews" USING "btree" ("parking_id");


--
-- TOC entry 4714 (class 1259 OID 27846)
-- Name: parkings_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "parkings_location_idx" ON "public"."parkings" USING "gist" ("location");


--
-- TOC entry 4759 (class 2620 OID 46429)
-- Name: reviews tr_1_calculate_review_score; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "tr_1_calculate_review_score" BEFORE INSERT OR UPDATE ON "public"."reviews" FOR EACH ROW EXECUTE FUNCTION "public"."handle_review_score_before"();


--
-- TOC entry 4760 (class 2620 OID 46430)
-- Name: reviews tr_2_aggregate_parkings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "tr_2_aggregate_parkings" AFTER INSERT OR DELETE OR UPDATE ON "public"."reviews" FOR EACH ROW EXECUTE FUNCTION "public"."aggregate_parking_stats_after"();


--
-- TOC entry 4757 (class 2620 OID 45358)
-- Name: parkings tr_init_parking_rating; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "tr_init_parking_rating" BEFORE INSERT ON "public"."parkings" FOR EACH ROW EXECUTE FUNCTION "public"."initialize_parking_rating"();


--
-- TOC entry 4758 (class 2620 OID 45436)
-- Name: users trigger_sync_user_data; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER "trigger_sync_user_data" AFTER INSERT OR UPDATE OF "full_name", "avatar_url" ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."sync_user_data_to_auth"();


--
-- TOC entry 4748 (class 2606 OID 46000)
-- Name: favorites favorites_parking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_parking_id_fkey" FOREIGN KEY ("parking_id") REFERENCES "public"."parkings"("id") ON DELETE CASCADE;


--
-- TOC entry 4749 (class 2606 OID 46946)
-- Name: favorites favorites_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;


--
-- TOC entry 4750 (class 2606 OID 41860)
-- Name: parking_photos parking_photos_parking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."parking_photos"
    ADD CONSTRAINT "parking_photos_parking_id_fkey" FOREIGN KEY ("parking_id") REFERENCES "public"."parkings"("id") ON DELETE CASCADE;


--
-- TOC entry 4751 (class 2606 OID 44228)
-- Name: parking_photos parking_photos_review_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."parking_photos"
    ADD CONSTRAINT "parking_photos_review_id_fkey" FOREIGN KEY ("review_id") REFERENCES "public"."reviews"("id") ON DELETE CASCADE;


--
-- TOC entry 4752 (class 2606 OID 45460)
-- Name: parking_photos parking_photos_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."parking_photos"
    ADD CONSTRAINT "parking_photos_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- TOC entry 4743 (class 2606 OID 46951)
-- Name: parkings parkings_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."parkings"
    ADD CONSTRAINT "parkings_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- TOC entry 4755 (class 2606 OID 46961)
-- Name: referral_stats referral_stats_referee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."referral_stats"
    ADD CONSTRAINT "referral_stats_referee_id_fkey" FOREIGN KEY ("referee_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;


--
-- TOC entry 4756 (class 2606 OID 46966)
-- Name: referral_stats referral_stats_referrer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."referral_stats"
    ADD CONSTRAINT "referral_stats_referrer_id_fkey" FOREIGN KEY ("referrer_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- TOC entry 4746 (class 2606 OID 26747)
-- Name: reports reports_parking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reports"
    ADD CONSTRAINT "reports_parking_id_fkey" FOREIGN KEY ("parking_id") REFERENCES "public"."parkings"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4747 (class 2606 OID 45465)
-- Name: reports reports_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reports"
    ADD CONSTRAINT "reports_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- TOC entry 4753 (class 2606 OID 44172)
-- Name: reviews reviews_parking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_parking_id_fkey" FOREIGN KEY ("parking_id") REFERENCES "public"."parkings"("id") ON DELETE CASCADE;


--
-- TOC entry 4754 (class 2606 OID 46956)
-- Name: reviews reviews_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- TOC entry 4744 (class 2606 OID 46941)
-- Name: users users_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;


--
-- TOC entry 4745 (class 2606 OID 46825)
-- Name: users users_referred_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_referred_by_id_fkey" FOREIGN KEY ("referred_by_id") REFERENCES "public"."users"("id");


--
-- TOC entry 4927 (class 3256 OID 41876)
-- Name: parking_photos Allow authenticated insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow authenticated insert" ON "public"."parking_photos" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));


--
-- TOC entry 4928 (class 3256 OID 47372)
-- Name: parkings Allow authenticated users to insert parkings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow authenticated users to insert parkings" ON "public"."parkings" FOR INSERT TO "authenticated" WITH CHECK (true);


--
-- TOC entry 4940 (class 3256 OID 47234)
-- Name: parking_photos Allow authenticated users to insert photos; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow authenticated users to insert photos" ON "public"."parking_photos" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));


--
-- TOC entry 4938 (class 3256 OID 47232)
-- Name: reports Allow authenticated users to insert reports; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow authenticated users to insert reports" ON "public"."reports" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));


--
-- TOC entry 4936 (class 3256 OID 47230)
-- Name: reviews Allow authenticated users to insert reviews; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow authenticated users to insert reviews" ON "public"."reviews" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));


--
-- TOC entry 4929 (class 3256 OID 47373)
-- Name: parkings Allow authenticated users to update parkings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow authenticated users to update parkings" ON "public"."parkings" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);


--
-- TOC entry 4926 (class 3256 OID 41875)
-- Name: parking_photos Allow public read access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow public read access" ON "public"."parking_photos" FOR SELECT USING (true);


--
-- TOC entry 4933 (class 3256 OID 47132)
-- Name: parkings Allow public read of approved parkings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow public read of approved parkings" ON "public"."parkings" FOR SELECT TO "authenticated", "anon" USING (("status" = 'approved'::"public"."parking_status"));


--
-- TOC entry 4935 (class 3256 OID 47134)
-- Name: reviews Allow public select of reviews; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow public select of reviews" ON "public"."reviews" FOR SELECT TO "authenticated", "anon" USING (true);


--
-- TOC entry 4948 (class 3256 OID 47374)
-- Name: parkings Allow public select on approved parkings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow public select on approved parkings" ON "public"."parkings" FOR SELECT TO "authenticated", "anon" USING ((("status" = 'approved'::"public"."parking_status") OR ("created_by" = "auth"."uid"()) OR "public"."is_admin"()));


--
-- TOC entry 4945 (class 3256 OID 45823)
-- Name: parking_photos Allow public select on parking photos; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow public select on parking photos" ON "public"."parking_photos" FOR SELECT USING (true);


--
-- TOC entry 4939 (class 3256 OID 47233)
-- Name: parking_photos Allow public select on parking_photos; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow public select on parking_photos" ON "public"."parking_photos" FOR SELECT TO "authenticated", "anon" USING (true);


--
-- TOC entry 4934 (class 3256 OID 47229)
-- Name: reviews Allow public select on reviews; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow public select on reviews" ON "public"."reviews" FOR SELECT TO "authenticated", "anon" USING (true);


--
-- TOC entry 4937 (class 3256 OID 47231)
-- Name: favorites Allow users to manage their own favorites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow users to manage their own favorites" ON "public"."favorites" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));


--
-- TOC entry 4946 (class 3256 OID 45824)
-- Name: parking_photos Authenticated can create parking photos; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated can create parking photos" ON "public"."parking_photos" FOR INSERT TO "authenticated" WITH CHECK (true);


--
-- TOC entry 4947 (class 3256 OID 45825)
-- Name: parking_photos Authenticated can delete parking photos; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated can delete parking photos" ON "public"."parking_photos" FOR DELETE TO "authenticated" USING (true);


--
-- TOC entry 4921 (class 0 OID 28989)
-- Dependencies: 401
-- Name: favorites; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE "public"."favorites" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4954 (class 3256 OID 46657)
-- Name: favorites favorites_owner_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "favorites_owner_all" ON "public"."favorites" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));


--
-- TOC entry 4922 (class 0 OID 41851)
-- Dependencies: 403
-- Name: parking_photos; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE "public"."parking_photos" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4918 (class 0 OID 25312)
-- Dependencies: 390
-- Name: parkings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE "public"."parkings" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4944 (class 3256 OID 46653)
-- Name: parkings parkings_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "parkings_delete" ON "public"."parkings" FOR DELETE TO "authenticated" USING ("public"."is_admin"());


--
-- TOC entry 4950 (class 3256 OID 46651)
-- Name: parkings parkings_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "parkings_insert" ON "public"."parkings" FOR INSERT TO "authenticated" WITH CHECK (true);


--
-- TOC entry 4949 (class 3256 OID 46650)
-- Name: parkings parkings_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "parkings_select" ON "public"."parkings" FOR SELECT USING ((("status" = 'approved'::"public"."parking_status") OR "public"."is_admin"()));


--
-- TOC entry 4943 (class 3256 OID 46652)
-- Name: parkings parkings_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "parkings_update" ON "public"."parkings" FOR UPDATE TO "authenticated" USING ((("auth"."uid"() = "created_by") OR "public"."is_admin"()));


--
-- TOC entry 4958 (class 3256 OID 46662)
-- Name: parking_photos photos_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "photos_delete" ON "public"."parking_photos" FOR DELETE TO "authenticated" USING (("public"."is_admin"() OR ("auth"."uid"() = "user_id")));


--
-- TOC entry 4957 (class 3256 OID 46661)
-- Name: parking_photos photos_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "photos_insert" ON "public"."parking_photos" FOR INSERT TO "authenticated" WITH CHECK (true);


--
-- TOC entry 4925 (class 3256 OID 47037)
-- Name: parking_photos photos_select_authenticated; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "photos_select_authenticated" ON "public"."parking_photos" FOR SELECT TO "authenticated" USING (true);


--
-- TOC entry 4924 (class 0 OID 46831)
-- Dependencies: 409
-- Name: referral_stats; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE "public"."referral_stats" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4920 (class 0 OID 26723)
-- Dependencies: 394
-- Name: reports; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE "public"."reports" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4956 (class 3256 OID 46659)
-- Name: reports reports_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "reports_insert" ON "public"."reports" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));


--
-- TOC entry 4955 (class 3256 OID 46658)
-- Name: reports reports_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "reports_select" ON "public"."reports" FOR SELECT TO "authenticated" USING ((("auth"."uid"() = "user_id") OR "public"."is_admin"()));


--
-- TOC entry 4923 (class 0 OID 44154)
-- Dependencies: 405
-- Name: reviews; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE "public"."reviews" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4953 (class 3256 OID 46656)
-- Name: reviews reviews_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "reviews_delete" ON "public"."reviews" FOR DELETE TO "authenticated" USING ("public"."is_admin"());


--
-- TOC entry 4952 (class 3256 OID 46655)
-- Name: reviews reviews_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "reviews_insert" ON "public"."reviews" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));


--
-- TOC entry 4951 (class 3256 OID 46654)
-- Name: reviews reviews_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "reviews_select" ON "public"."reviews" FOR SELECT USING (true);


--
-- TOC entry 4919 (class 0 OID 25572)
-- Dependencies: 393
-- Name: users; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4931 (class 3256 OID 47506)
-- Name: users users_insert_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "users_insert_all" ON "public"."users" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);


--
-- TOC entry 4930 (class 3256 OID 47505)
-- Name: users users_select_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "users_select_all" ON "public"."users" FOR SELECT TO "authenticated", "anon" USING (true);


--
-- TOC entry 4941 (class 3256 OID 47508)
-- Name: users users_select_all_clean; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "users_select_all_clean" ON "public"."users" FOR SELECT TO "authenticated" USING (true);


--
-- TOC entry 4932 (class 3256 OID 47507)
-- Name: users users_update_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "users_update_own" ON "public"."users" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id"));


--
-- TOC entry 4942 (class 3256 OID 47509)
-- Name: users users_update_own_clean; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "users_update_own_clean" ON "public"."users" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id"));


-- pg_dump was intentionally produced without ACL statements. Reproduce the
-- current hosted users grants required by the following hardening migration.
GRANT ALL PRIVILEGES ON TABLE "public"."users" TO "anon";
GRANT ALL PRIVILEGES ON TABLE "public"."users" TO "authenticated";
GRANT ALL PRIVILEGES ON TABLE "public"."users" TO "service_role";

-- The public-only dump cannot include a trigger owned by the auth schema.
-- Recreate the trigger captured separately in backend metadata for local parity.
DROP TRIGGER IF EXISTS "on_auth_user_created" ON "auth"."users";
CREATE TRIGGER "on_auth_user_created"
AFTER INSERT ON "auth"."users"
FOR EACH ROW EXECUTE FUNCTION "public"."handle_new_auth_user"();


-- Completed on 2026-07-23 20:04:57 MSK

--
-- PostgreSQL database dump complete
--
