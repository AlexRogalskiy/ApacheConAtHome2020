CREATE TABLE ItemTransactions (
	transactionId    BIGINT,
	ts    BIGINT,
	itemId    STRING,
	quantity INT,
	event_time AS CAST(from_unixtime(floor(ts/1000)) AS TIMESTAMP(3)),
	WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
) WITH (
	'connector.type'    	 = 'kafka',
	'connector.version' 	 = 'universal',
	'connector.topic'   	 = 'transaction.log.1',
	'connector.startup-mode' = 'earliest-offset',
	'connector.properties.bootstrap.servers' = 'edge2ai-1.dim.local:9092',
	'format.type' = 'json'
);

CREATE TABLE WindowedQuantity (
	window_start    TIMESTAMP(3),
	itemId    STRING,
	volume INT
) WITH (
	'connector.type'    	 = 'kafka',
	'connector.version' 	 = 'universal',
	'connector.topic'   	 = 'transaction.output.log',
	'connector.properties.bootstrap.servers' = 'edge2ai-1.dim.local:9092',
	'format.type' = 'json'
);

INSERT INTO WindowedQuantity
SELECT TUMBLE_START(event_time, INTERVAL '10' SECOND) as window_start, itemId, sum(quantity) as volume
FROM ItemTransactions
GROUP BY itemId, TUMBLE(event_time, INTERVAL '10' SECOND);
