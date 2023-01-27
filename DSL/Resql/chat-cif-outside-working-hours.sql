WITH config AS (
    SELECT 
        (SELECT value FROM configuration WHERE key = 'organizationWorkingTimeStartISO')::timestamptz AS workingTimeStart,
        (SELECT value FROM configuration WHERE key = 'organizationWorkingTimeEndISO')::timestamptz AS workingTimeEnd
)
SELECT
    DATE_TRUNC(:period, chat.created) AS time,
    COUNT(DISTINCT base_id)
FROM chat  
JOIN customer_support_agent_activity AS csa
ON chat.customer_support_id = csa.id_code
WHERE chat.created BETWEEN :start::timestamptz AND :end::timestamptz
AND EXISTS (
    SELECT 1
    FROM message
    WHERE message.chat_base_id = chat.base_id
    AND message.event = 'contact-information-fulfilled'
    AND (
		EXTRACT(HOUR FROM message.created)
		NOT BETWEEN EXTRACT(HOUR FROM (SELECT workingTimeStart FROM config)) 
		AND EXTRACT(HOUR FROM (SELECT workingTimeEnd FROM config))
	)
)
GROUP BY time
ORDER BY time