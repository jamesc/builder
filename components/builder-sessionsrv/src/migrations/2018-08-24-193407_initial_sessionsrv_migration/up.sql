CREATE SEQUENCE accounts_id_seq; 
CREATE SEQUENCE account_tokens_id_seq;
CREATE SEQUENCE account_invitations_id_seq;

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

CREATE TABLE account_invitations (
    id bigint DEFAULT next_id_v1('account_invitations_id_seq') PRIMARY KEY NOT NULL,
    origin_invitation_id bigint,
    origin_id bigint,
    origin_name text,
    account_id bigint REFERENCES accounts(id),
    account_name text REFERENCES accounts(name),
    owner_id bigint,
    ignored boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE (origin_id, account_id) 
);

CREATE FUNCTION accept_account_invitation_v1(oi_invite_id bigint, oi_ignore boolean) RETURNS void
    LANGUAGE plpgsql
    AS $$
  DECLARE
    oi_origin_id bigint;
    oi_origin_name text;
    oi_account_id bigint;
    oi_account_name text;
  BEGIN
    IF oi_ignore = true THEN
      UPDATE account_invitations SET ignored = true, updated_at = now() WHERE origin_invitation_id = oi_invite_id;
    ELSE
      SELECT origin_id, origin_name, account_id, account_name INTO oi_origin_id, oi_origin_name, oi_account_id, oi_account_name FROM account_invitations WHERE origin_invitation_id = oi_invite_id;
      PERFORM insert_account_origin_v1(oi_account_id, oi_account_name, oi_origin_id, oi_origin_name);
      DELETE FROM account_invitations WHERE origin_invitation_id = oi_invite_id;
    END IF;
  END
$$;

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

CREATE FUNCTION get_invitations_for_account_v1(oi_account_id bigint) RETURNS SETOF account_invitations
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT * FROM account_invitations WHERE account_id = oi_account_id AND ignored = false
      ORDER BY origin_name ASC;
    RETURN;
  END
$$;

CREATE FUNCTION ignore_account_invitation_v1(oi_invitation_id bigint, oi_account_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
  UPDATE account_invitations
  SET ignored = true, updated_at = now()
  WHERE origin_invitation_id = oi_invitation_id AND account_id = oi_account_id;
$$;

CREATE FUNCTION insert_account_invitation_v1(oi_origin_id bigint, oi_origin_name text, oi_origin_invitation_id bigint, oi_account_id bigint, oi_account_name text, oi_owner_id bigint) RETURNS SETOF account_invitations
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF NOT EXISTS (SELECT true FROM account_origins WHERE origin_id = oi_origin_id AND account_id = oi_account_id) THEN
      RETURN QUERY INSERT INTO account_invitations (origin_id, origin_invitation_id, origin_name, account_id, account_name, owner_id)
        VALUES (oi_origin_id, oi_origin_invitation_id, oi_origin_name, oi_account_id, oi_account_name, oi_owner_id)
        ON CONFLICT DO NOTHING
        RETURNING *;
      RETURN;
    END IF;
  END
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

CREATE FUNCTION rescind_account_invitation_v1(oi_invitation_id bigint, oi_account_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
  DELETE FROM account_invitations
  WHERE origin_invitation_id = oi_invitation_id
  AND account_id = oi_account_id
  AND ignored = false;
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
