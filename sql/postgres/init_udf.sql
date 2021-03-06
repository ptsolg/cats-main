/*
Note that:
A cast to or from a domain type currently has no effect.
Casting to or from a domain uses the casts associated with its underlying type.
*/

/* Firebird-specific casts. */
CREATE FUNCTION INTERVAL_TO_DOUBLE(i INTERVAL)
RETURNS DOUBLE PRECISION AS
$$
BEGIN
    RETURN (EXTRACT(EPOCH FROM i) / 3600.0) / 24.0;
END;
$$
LANGUAGE PLPGSQL;

CREATE FUNCTION INTERVAL_TO_NUMERIC(i INTERVAL)
RETURNS NUMERIC AS
$$
BEGIN
    RETURN (EXTRACT(EPOCH FROM i) / 3600.0) / 24.0;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION BYTEA_TO_TEXT(BYTEA)
RETURNS TEXT AS
$$
BEGIN
    RETURN CONVERT_FROM($1, 'UTF-8');
END;
$$
LANGUAGE PLPGSQL;

CREATE CAST (INTERVAL AS DOUBLE PRECISION)
WITH FUNCTION INTERVAL_TO_DOUBLE(INTERVAL) AS IMPLICIT;

CREATE CAST (INTERVAL AS NUMERIC)
WITH FUNCTION INTERVAL_TO_NUMERIC(INTERVAL) AS IMPLICIT;

CREATE CAST (BYTEA AS TEXT)
WITH FUNCTION BYTEA_TO_TEXT(BYTEA) AS IMPLICIT;

/* Firebird-specific TIMESTAMP operators. */
CREATE FUNCTION TIMESTAMPTZ_SUB_ANY(t TIMESTAMPTZ, v ANYELEMENT)
RETURNS TIMESTAMPTZ AS
$$
BEGIN
    RETURN t - MAKE_INTERVAL(SECS => CAST(v * 86400 AS INTEGER));
END;
$$
LANGUAGE PLPGSQL;

CREATE FUNCTION TIMESTAMPTZ_ADD_ANY(t TIMESTAMPTZ, v ANYELEMENT)
RETURNS TIMESTAMPTZ AS
$$
BEGIN
    RETURN t + MAKE_INTERVAL(SECS => CAST(v * 86400 AS INTEGER));
END;
$$
LANGUAGE PLPGSQL;

CREATE OPERATOR - (
    LEFTARG = TIMESTAMPTZ,
    RIGHTARG = ANYELEMENT,
    PROCEDURE = TIMESTAMPTZ_SUB_ANY,
    COMMUTATOR = -
);

CREATE OPERATOR + (
    LEFTARG = TIMESTAMPTZ,
    RIGHTARG = ANYELEMENT,
    PROCEDURE = TIMESTAMPTZ_ADD_ANY,
    COMMUTATOR = +
);

/*  */
CREATE FUNCTION BIN_AND(l ANYELEMENT, r ANYELEMENT)
RETURNS ANYELEMENT AS
$$
BEGIN
    RETURN l & r;
END;
$$
LANGUAGE PLPGSQL;

CREATE FUNCTION MAXVALUE(ANYELEMENT, ANYELEMENT)
RETURNS ANYELEMENT AS
$$
BEGIN
    IF $1 IS NULL OR $2 IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN GREATEST($1, $2);
    END IF;
END;
$$
LANGUAGE PLPGSQL;

/* Emulate firebird's LIST(...) aggregate function. */
CREATE FUNCTION LIST_AGG(state TEXT, next_elem ANYELEMENT, delim TEXT)
RETURNS TEXT AS
$$
BEGIN
    IF state IS NULL THEN
        RETURN CAST(next_elem AS TEXT);
    ELSIF next_elem IS NULL THEN
        RETURN state;
    ELSE
        RETURN state || delim || CAST(next_elem AS TEXT);
    END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE FUNCTION LIST_AGG(state TEXT, next_elem ANYELEMENT)
RETURNS TEXT AS
$$
BEGIN
    RETURN LIST_AGG(state, next_elem, ',');
END;
$$
LANGUAGE PLPGSQL;

CREATE AGGREGATE LIST(ANYELEMENT, TEXT) (
    SFUNC = LIST_AGG,
    STYPE = TEXT
);

CREATE AGGREGATE LIST(ANYELEMENT) (
    SFUNC = LIST_AGG,
    STYPE = TEXT
);
