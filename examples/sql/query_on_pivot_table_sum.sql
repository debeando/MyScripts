USE test;

CREATE TABLE foo (
  id       BIGINT(20) NOT NULL AUTO_INCREMENT,
  country  CHAR(2) NOT NULL,
  category CHAR(1) NOT NULL,
  PRIMARY KEY (`id`)
);

INSERT INTO foo (
  country,
  category
)
VALUES
  ('BR', 'A'),
  ('BR', 'A'),
  ('BR', 'B'),
  ('BR', 'C'),
  ('CA', 'A'),
  ('CA', 'B'),
  ('CA', 'B'),
  ('CA', 'C'),
  ('MX', 'A'),
  ('MX', 'B'),
  ('MX', 'C'),
  ('MX', 'C');

SELECT
  category,
  COUNT(CASE WHEN country = 'BR' THEN 1 ELSE NULL END) AS 'BR',
  COUNT(CASE WHEN country = 'CA' THEN 1 ELSE NULL END) AS 'CA',
  COUNT(CASE WHEN country = 'MX' THEN 1 ELSE NULL END) AS 'MX'
FROM foo
GROUP BY category
ORDER BY category;
