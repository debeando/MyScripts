-- https://dev.mysql.com/doc/refman/5.6/en/numeric-type-attributes.html

Investigando me consegui con esta documentación y probando pude demostrar para que sirve la longitud al momento de
declarar el tipo de dato entero, se usa para definir la longitud de relleno de
"0" a la izquierda cuando se hace un SELECT, y esto solo se puede aplicar cuando
defines la columna con la opción ZEROFILL.

En el siguiente ejemplo creo una tabla en la base de datos test llamada demo,
vamos a probar con el tipo de dato TINYINT  y muestro como se crea por defecto por MySQL:

USE test;

DROP TABLE IF EXISTS demo;
CREATE TABLE IF NOT EXISTS demo (
  id           INT NOT NULL AUTO_INCREMENT,
  demo TINYINT NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

SHOW CREATE TABLE demo;

# +-------+----------------------------------------------------+
# | Table | Create Table                                       |
# +-------+----------------------------------------------------+
# | demo  | CREATE TABLE `demo` (
#   `id` int(11) NOT NULL AUTO_INCREMENT,
#   `demo` tinyint(4) NOT NULL DEFAULT '0',
#   PRIMARY KEY (`id`)
# ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci |
# +-------+----------------------------------------------------+



INSERT INTO demo (demo) VALUES (
  127 -- Valor maximo, longitud 3 caracteres.
);

INSERT INTO demo (demo) VALUES (
  12 -- Valor menor, longitud 2 caracteres.
);

INSERT INTO demo (demo) VALUES (
  1 -- Valor menor, longitud 2 caracteres.
);

SELECT * FROM demo;
+----+------+
| id | demo |
+----+------+
|  1 |  127 |
|  2 |   12 |
|  3 |    1 |
+----+------+

ALTER TABLE demo MODIFY demo TINYINT(2);

SELECT * FROM demo;
+----+------+
| id | demo |
+----+------+
|  1 |  127 |
|  2 |   12 |
|  3 |    1 |
+----+------+

ALTER TABLE demo MODIFY demo TINYINT(2) ZEROFILL;

+----+------+
| id | demo |
+----+------+
|  1 |  127 |
|  2 |  127 |
|  3 |   12 |
|  4 |   01 |
+----+------+

ALTER TABLE demo MODIFY demo TINYINT(3) ZEROFILL;

+----+------+
| id | demo |
+----+------+
|  1 |  127 |
|  2 |  127 |
|  3 |  012 |
|  4 |  001 |
+----+------+
