CREATE SEQUENCE accounts_id_seq; 
CREATE SEQUENCE account_tokens_id_seq;

CREATE TABLE accounts (
    id bigint DEFAULT next_id_v1('accounts_id_seq') PRIMARY KEY NOT NULL,
    name text UNIQUE,
    email text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE account_origins (
    account_id bigint,
    account_name text,
    origin_id bigint,
    origin_name text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE (account_id, origin_id)
);

CREATE TABLE account_tokens (
    id bigint DEFAULT next_id_v1('account_tokens_id_seq') PRIMARY KEY NOT NULL,
    account_id bigint,
    token text UNIQUE,
    created_at timestamp with time zone DEFAULT now()
);

CREATE FUNCTION delete_account_origin_v1(aod_account_name text, aod_origin_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
    DELETE FROM account_origins WHERE account_name=aod_account_name AND origin_id=aod_origin_id;
$$;

CREATE FUNCTION get_account_by_id_v1(account_id bigint) RETURNS SETOF accounts
    LANGUAGE plpgsql STABLE
    AS $$
    BEGIN
      RETURN QUERY SELECT * FROM accounts WHERE id = account_id;
      RETURN;
    END
$$;

CREATE FUNCTION get_account_by_name_v1(account_name text) RETURNS SETOF accounts
    LANGUAGE plpgsql STABLE
    AS $$
    BEGIN
      RETURN QUERY SELECT * FROM accounts WHERE name = account_name;
      RETURN;
    END
$$;

CREATE FUNCTION get_account_origins_v1(in_account_id bigint) RETURNS SETOF account_origins
    LANGUAGE plpgsql STABLE
    AS $$
    BEGIN
      RETURN QUERY SELECT * FROM account_origins WHERE account_id = in_account_id;
      RETURN;
    END
$$;

CREATE FUNCTION get_account_token_with_id_v1(p_id bigint) RETURNS SETOF account_tokens
    LANGUAGE sql STABLE
    AS $$
    SELECT * FROM account_tokens WHERE id = p_id;
$$;

CREATE FUNCTION get_account_tokens_v1(p_account_id bigint) RETURNS SETOF account_tokens
    LANGUAGE sql STABLE
    AS $$
    SELECT * FROM account_tokens WHERE account_id = p_account_id;
$$;

CREATE FUNCTION insert_account_origin_v1(o_account_id bigint, o_account_name text, o_origin_id bigint, o_origin_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
    BEGIN
      INSERT INTO account_origins (account_id, account_name, origin_id, origin_name) VALUES (o_account_id, o_account_name, o_origin_id, o_origin_name);
    END
$$;

CREATE FUNCTION insert_account_token_v1(p_account_id bigint, p_token text) RETURNS SETOF account_tokens
    LANGUAGE sql
    AS $$
    DELETE FROM account_tokens WHERE account_id = p_account_id;
    INSERT INTO account_tokens (account_id, token)
    VALUES (p_account_id, p_token)
    RETURNING *;
$$;

CREATE FUNCTION revoke_account_token_v1(p_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
    DELETE FROM account_tokens WHERE id = p_id;
$$;

CREATE FUNCTION select_or_insert_account_v1(account_name text, account_email text) RETURNS SETOF accounts
    LANGUAGE plpgsql
    AS $$
    DECLARE
      existing_account accounts%rowtype;
    BEGIN
      SELECT * INTO existing_account FROM accounts WHERE name = account_name LIMIT 1;
      IF FOUND THEN
          RETURN NEXT existing_account;
      ELSE
          RETURN QUERY INSERT INTO accounts (name, email) VALUES (account_name, account_email) ON CONFLICT DO NOTHING RETURNING *;
      END IF;
      RETURN;
    END
$$;

CREATE FUNCTION update_account_v1(op_id bigint, op_email text) RETURNS void
    LANGUAGE sql
    AS $$
    UPDATE accounts SET email = op_email WHERE id = op_id;
$$;
