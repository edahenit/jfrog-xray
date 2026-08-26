SELECT
  current_setting('max_connections')::int AS max_connections,
  count(*) AS current_connections,
  round(count(*) * 100.0
        / current_setting('max_connections')::int, 2) AS pct_used
FROM pg_stat_activity
WHERE backend_type = 'client backend';

SELECT
  current_setting('max_connections')::int AS max_connections,
  count(*) AS current_connections,
  round(count(*) * 100.0
        / current_setting('max_connections')::int, 2) AS pct_used
FROM pg_stat_activity
WHERE backend_type = 'client backend';

SELECT state, count(*) FROM pg_stat_activity GROUP BY state;



SELECT
  pid,
  usename,
  now() - query_start AS duration,
  state,
  wait_event_type,
  wait_event,
  query
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY duration DESC
LIMIT 10;
