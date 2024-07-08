CREATE TYPE nivel_riesgo AS ENUM ('alto', 'medio', 'bajo');
CREATE TYPE plazo_inversion AS ENUM ('corto', 'medio', 'largo');

CREATE TABLE activo (
    id_activo VARCHAR(12) PRIMARY KEY,
    riesgo nivel_riesgo,
    plazo plazo_inversion
);

CREATE TABLE acciones (
    ent_emisora VARCHAR(30),
	valor_mercado DECIMAL(6,2),
	UNIQUE (id_activo)
) INHERITS (activo);


CREATE TABLE bonos (
    ent_emisora VARCHAR(30),
    v_nominal DECIMAL(6,2),
    tasa_interes DECIMAL(4,2),
    fecha_emision DATE,
    fecha_venc DATE,
	valor_mercado DECIMAL(6,2),
	UNIQUE (id_activo)
) INHERITS (activo);


CREATE TABLE depositos (
    nombre_banco VARCHAR(30),
    interes DECIMAL(4,2),
    plazo_dias INT,
	UNIQUE (id_activo)
) INHERITS (activo);


CREATE TABLE usuarios (
    NIF_CIF VARCHAR(9) PRIMARY KEY,
    nombre VARCHAR(30)
);


CREATE TYPE tipo_op AS ENUM ('compra', 'venta');
create table operaciones(
    id_operacion SERIAL PRIMARY KEY,
    id_usuario VARCHAR(9),
    id_activo VARCHAR(12),
    fecha_op DATE,
    tipo_operacion tipo_op,
    precio DECIMAL(6,2),
	cantidad INT,
    CONSTRAINT fk_operaciones_usuarios FOREIGN KEY (id_usuario) REFERENCES usuarios(NIF_CIF),
    CONSTRAINT fk_operaciones_activos FOREIGN KEY (id_activo) REFERENCES activo(id_activo)
);


-- CREO LAS DIFERENTES VISTAS

CREATE VIEW cartera_acciones as
	SELECT 
		o.id_usuario, 
		o.id_activo, 
		a.ent_emisora, 
		o.cantidad, 
		o.precio as precio_compra, 
		o.fecha_op as fecha_compra, 
		a.valor_mercado as precio_actual, 
		o.cantidad*a.valor_mercado as valor_actual,
		(o.cantidad*a.valor_mercado - o.cantidad*o.precio) as variacion_euro
	FROM 
		operaciones as o
	JOIN 
		acciones as a on o.id_activo=a.id_activo;
		

CREATE VIEW cartera_bonos as
	SELECT 
		o.id_usuario, 
		o.id_activo, 
		b.ent_emisora, 
		b.tasa_interes as tipo_interes, 
		b.v_nominal, 
		b.fecha_emision, 
		b.fecha_venc, 
		o.fecha_op as fecha_compra, 
		o.cantidad, 
		o.precio as precio_compra, 
		b.valor_mercado as precio_actual, 
		o.cantidad*b.valor_mercado as valor_actual,
		(o.cantidad*b.valor_mercado - o.cantidad*o.precio) as variacion_euro
	FROM 
		operaciones as o
	JOIN 
		bonos as b on o.id_activo = b.id_activo;


CREATE VIEW cartera_depositos AS
	SELECT 
    	o.id_usuario, 
   	 	o.id_activo, 
    	d.nombre_banco, 
    	o.cantidad AS saldo, 
    	d.interes AS tipo_interes,
		d.plazo_dias AS plazo_dias,
    	o.fecha_op AS fecha_contratacion, 
    	ROUND(o.cantidad * (1 + d.interes / 100 * (CURRENT_DATE - o.fecha_op) / 365.0), 2) AS valor_actual,
    	(ROUND(o.cantidad * (1 + d.interes / 100 * (CURRENT_DATE - o.fecha_op) / 365.0), 2) - o.cantidad) AS variacion_euro
	FROM 
    	operaciones AS o
	JOIN 
    	depositos AS d ON o.id_activo = d.id_activo;


CREATE VIEW total_cartera AS
    SELECT 
        'Acción' AS tipo_activo,
        ca.id_usuario,
        ca.id_activo,
        ca.ent_emisora,
        ca.cantidad,
        ca.precio_compra,
        ca.fecha_compra,
        ca.precio_actual,
        ca.valor_actual,
        ROUND(ca.valor_actual - (ca.cantidad * ca.precio_compra), 2) AS variacion_euro
    FROM 
        cartera_acciones AS ca
    UNION ALL
    SELECT 
        'Bono' AS tipo_activo,
        cb.id_usuario,
        cb.id_activo,
        cb.ent_emisora,
        cb.cantidad,
        cb.precio_compra,
        cb.fecha_compra,
        cb.precio_actual,
        cb.valor_actual,
        ROUND(cb.valor_actual - (cb.cantidad * cb.precio_compra), 2) AS variacion_euro
    FROM 
        cartera_bonos AS cb
    UNION ALL
    SELECT 
        'Depósito' AS tipo_activo,
        cd.id_usuario,
        cd.id_activo,
        cd.nombre_banco AS ent_emisora,
        cd.saldo AS cantidad,
        NULL AS precio_compra,
        cd.fecha_contratacion AS fecha_compra,
        NULL AS precio_actual,
        cd.valor_actual,
        ROUND(cd.valor_actual - cd.saldo, 2) AS variacion_euro
    FROM 
        cartera_depositos AS cd;


-- INSERTO DATOS

INSERT INTO activo (id_activo, riesgo, plazo) VALUES 
    ('ES0113900J37', 'alto', 'corto'),
    ('ES0113211835', 'alto', 'corto'),
    ('NL0015001FS8', 'alto', 'corto'),
    ('ES0167050915', 'alto', 'corto'),
    ('ES0118594417', 'alto', 'corto'),
    ('ES0178430E18', 'alto', 'corto'),
    ('ES0132105018', 'alto', 'corto'),
    ('US30303M1027', 'alto', 'corto'), 
    ('US0378331005', 'alto', 'corto'),
    ('US02079K1079', 'alto', 'corto');

INSERT INTO acciones (id_activo, valor_mercado, ent_emisora) VALUES 
	('ES0113900J37', '4.40', 'Banco Santander'),
 	('ES0113211835', '9.65', 'BBVA'),
	('NL0015001FS8', '37.38', 'Ferrovial'),
	('ES0167050915', '39.14', 'ACS'),
	('ES0118594417', '19.10', 'Indra'),
	('ES0178430E18', '3.94', 'Telefonica'),
	('ES0132105018', '9.99', 'Acerinox'),
	('US30303M1027', '539.82', 'Meta'), 
	('US0378331005', '226.02', 'Apple'),
	('US02079K1079', '191.2', 'Alphabet');


INSERT INTO usuarios (nif_cif, nombre) VALUES
	('24081230T', 'Fernando Jose Perez Gonzalez'),
	('46375190Z', 'Alberto Rebollo Diaz'),
	('A66172289', 'Transportes Mariano'),
	('C01320522', 'Inmobiliaria Sotogrande'),
	('A01081496', 'Inversiones Manuel');


INSERT INTO operaciones (id_usuario,id_activo,fecha_op, tipo_operacion, precio, cantidad) VALUES
	('24081230T', 'ES0113900J37', '2024-06-27', 'compra', '4.07', '2150'),
	('46375190Z', 'ES0113211835', '2024-01-27', 'compra', '9.26', '1430'),
	('A66172289', 'NL0015001FS8','2024-02-27', 'compra', '32.91', '2240'),
	('C01320522', 'ES0167050915',  '2024-06-21', 'compra','41.45', '1810'),
	('A01081496', 'ES0118594417', '2024-04-22', 'compra', '17.31', '2500'),
	('A01081496', 'ES0178430E18', '2024-03-15', 'compra','3.33', '3590'),
	('A66172289', 'ES0132105018', '2024-04-12', 'compra', '9.6', '2660'),
	('C01320522', 'US30303M1027', '2024-06-02', 'compra','512.39','200'),
	('46375190Z','US0378331005', '2024-05-15', 'compra', '199.66', '390'),
	('A01081496','US02079K1079', '2024-03-27', 'compra', '166.83', '250'),
	('24081230T','ES0118594417', '2024-02-27', 'compra', '16.07', '1157'),
	('C01320522','ES0178430E18', '2024-02-27', 'compra', '3.26', '2430');


INSERT INTO activo (id_activo, riesgo, plazo) VALUES
	('US2464023022', 'medio', 'largo'),
	('US5773852050', 'medio', 'largo'),
	('US4517843362', 'medio', 'largo'),
	('DE4688429622', 'medio', 'largo'),
	('US8320910204', 'medio', 'largo'),
	('DE5794379848', 'medio', 'largo'),
	('DE8694634621', 'medio', 'largo');
	

INSERT INTO bonos (id_activo, valor_mercado, ent_emisora, v_nominal, tasa_interes, fecha_emision, fecha_venc) VALUES 
	('US2464023022', '8921.81', 'Hamill LLC', '8384.35', '5.29', '2024-03-06', '2025-03-05'),
	('US5773852050', '5626.29', 'Labadie, Ryan and Bartoletti', '5950.4', '7.92', '2023-11-22', '2024-07-17'),
	('US4517843362', '1629.25', 'Will LLC', '1584.79', '4.04', '2023-10-22', '2024-10-07'),
	('DE4688429622', '6713.39', 'Kohler, Lueilwitz and Lang', '5943.18', '2.18', '2024-05-15', '2024-10-29'),
	('US8320910204', '5647.2', 'Crooks - Hills', '5810.57', '5.18', '2024-02-15', '2025-02-20'),
	('DE5794379848', '8719.31', 'Grimes, Kiehn and Feeney', '7588.47', '3.7', '2023-08-28', '2024-12-17'),
	('DE8694634621', '3290.46', 'Kuhlman - Wolff', '3120.76', '4.84', '2024-02-28', '2025-06-17');


INSERT INTO activo (id_activo, riesgo, plazo) VALUES
	('6494947', 'bajo', 'medio'),
	('1869093','bajo', 'medio'),
	('4442948', 'bajo', 'medio'),
	('08077806','bajo', 'medio'),
	('3595484', 'bajo', 'medio'),
	('9099701','bajo', 'medio'),
	('5192699','bajo', 'medio'),
	('3919556', 'bajo', 'medio');
	
INSERT INTO depositos (id_activo, nombre_banco, interes, plazo_dias) VALUES 
	('6494947', 'Schmidt and Sons', '2.50', '180'),
	('1869093', 'Von - Ruecker', '4.60', '30'),
	('4442948', 'Wolf Inc', '1.15', '360'),
	('08077806', 'Gutmann Group', '2.25', '180'),
	('3595484', 'Littel, Mann and Friesen', '2.9', '120'),
	('9099701', 'Wiza - Medhurst', '3.95', '90'),
	('3919556', 'Smith, Donnelly and Fahey', '3.30', '120');


INSERT INTO operaciones (id_usuario,id_activo,fecha_op, tipo_operacion, precio, cantidad) VALUES
	('24081230T', 'US2464023022', '2024-05-27', 'compra', '9050.07', '10'),
	('46375190Z', 'US5773852050', '2024-01-27', 'compra', '5915.26', '15'),
	('A66172289', 'US4517843362','2024-02-27', 'compra', '1512.91', '30'),
	('C01320522', 'DE4688429622',  '2024-06-21', 'compra','6881.45', '20'),
	('A01081496', 'US8320910204', '2024-04-22', 'compra', '5727.31', '15'),
	('A01081496', 'DE5794379848', '2024-03-15', 'compra','9359.33', '10'),
	('A66172289', 'DE8694634621', '2024-04-12', 'compra', '3546.6', '40'),
	('C01320522', 'DE5794379848', '2024-06-02', 'compra','9552.39','12');

INSERT INTO operaciones (id_usuario,id_activo,fecha_op, tipo_operacion, cantidad) VALUES
	('24081230T', '6494947', '2024-05-27', 'compra', '100000'),
	('46375190Z', '1869093', '2024-01-27', 'compra', '150000'),
	('A66172289', '4442948','2024-02-27', 'compra', '300000'),
	('C01320522', '08077806',  '2024-06-21', 'compra', '20000'),
	('A01081496', '3595484', '2024-04-22', 'compra', '150000'),
	('A01081496', '9099701', '2024-03-15', 'compra', '100000'),
	('A66172289', '3919556', '2024-04-12', 'compra', '400000'),
	('C01320522', '3919556', '2024-06-02', 'compra', '120000');





-- NIVEL 1: CONSULTAS BÁSICAS

-- 1. Listar todos los usuarios registrados en el sistema.

select * from usuarios;


-- 2. Mostrar todos los activos de un usuario específico.

select * from total_cartera where id_usuario='A66172289';


-- 3. Encontrar todos los bonos con una tasa de interés superior al 5%.

select * from bonos where tasa_interes > 5;


-- 4. Listar todas las acciones ordenadas por fecha de adquisición.

select * from cartera_acciones order by fecha_compra;


-- 5. Mostrar los depósitos bancarios con un saldo superior a $10,000

select * from cartera_depositos where saldo > '10000';


-- NIVEL 2 - CONSULTAS INTERMEDIAS

-- 6. Calcular el valor total de todos los activos de un usuario específico.

select SUM(valor_actual) as valor_total from total_cartera where id_usuario='A66172289';


-- 7. Encontrar los 2 usuarios con mayor cantidad de acciones.

SELECT 
    id_usuario, SUM(cantidad) AS total_acciones
FROM 
    cartera_acciones
GROUP BY 
    id_usuario
ORDER BY 
    total_acciones DESC
LIMIT 2;


-- 8. Listar los bonos que vencerán en los próximos 30 días.

SELECT 
    id_activo, ent_emisora, v_nominal, fecha_emision, fecha_venc
FROM 
    bonos
WHERE 
    fecha_venc BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '30 days');


-- 9. Mostrar el promedio de tasas de interés de los depósitos bancarios por banco.

SELECT 
    nombre_banco, ROUND(AVG(interes), 2) AS promedio_interes
FROM 
    depositos
GROUP BY 
    nombre_banco;


-- 10. Encontrar las acciones que han tenido un aumento de valor mayor al 10% desde su compra.

SELECT * FROM acciones;

SELECT
    o.id_usuario, o.id_activo AS ISIN, a.ent_emisora, o.cantidad, o.precio AS precio_compra, a.valor_mercado AS precio_actual,
    ROUND(((a.valor_mercado - o.precio) / o.precio) * 100, 2) AS porcentaje_aumento
FROM
    operaciones AS o
JOIN
    acciones AS a ON o.id_activo = a.id_activo
WHERE
    ((a.valor_mercado - o.precio) / o.precio) * 100 > 10
    AND o.tipo_operacion = 'compra';


-- NIVEL 3 - CONSULTAS AVANZADAS

-- 11. Calcular el rendimiento (en porcentaje) de cada activo en el último año.

-- Para esta consulta necesitaría datos del último año del valor de los activos, y no los tengo.


-- 12. Listar los usuarios junto con su activo de mayor valor y el tipo de este activo.

WITH valor_activos AS (
    SELECT 
        o.id_usuario, o.id_activo, a.valor_mercado AS valor_actual, 'acciones' AS tipo_activo
    FROM 
        operaciones o
    JOIN 
        acciones a ON o.id_activo = a.id_activo
    UNION ALL
    SELECT 
        o.id_usuario, o.id_activo, b.valor_mercado AS valor_actual, 'bonos' AS tipo_activo
    FROM 
        operaciones o
    JOIN 
        bonos b ON o.id_activo = b.id_activo
    UNION ALL
    SELECT 
        o.id_usuario, o.id_activo, cd.saldo AS valor_actual, 'depositos' AS tipo_activo
    FROM 
        operaciones o
    JOIN 
        cartera_depositos cd ON o.id_activo = cd.id_activo
),
max_valor_activo AS (
    SELECT 
        id_usuario, MAX(valor_actual) AS max_valor
    FROM 
        valor_activos
    GROUP BY 
        id_usuario
)
SELECT 
    u.nif_cif AS usuario_id,
    u.nombre AS nombre_usuario,
    va.id_activo AS activo_id,
    va.tipo_activo,
    va.valor_actual AS valor_del_activo
FROM 
    max_valor_activo mva
JOIN 
    valor_activos va ON mva.id_usuario = va.id_usuario AND mva.max_valor = va.valor_actual
JOIN 
    usuarios u ON u.nif_cif = mva.id_usuario
ORDER BY 
    usuario_id;


-- 13. Encontrar los pares de usuarios que tienen acciones de las mismas empresas.

WITH usuarios_acciones AS (
    SELECT 
        o.id_usuario, a.ent_emisora, o.id_activo
    FROM 
        operaciones o
    JOIN 
        acciones a ON o.id_activo = a.id_activo
)
SELECT 
    ua1.id_usuario AS usuario_1,
    ua2.id_usuario AS usuario_2,
    ua1.ent_emisora AS empresa
FROM 
    usuarios_acciones ua1
JOIN 
    usuarios_acciones ua2 ON ua1.ent_emisora = ua2.ent_emisora
WHERE 
    ua1.id_usuario < ua2.id_usuario
ORDER BY 
    usuario_1, usuario_2, empresa;


-- 14. Calcular la diversificación de la cartera de cada usuario (porcentaje de cada tipo de activo).

WITH total_activos AS (
    SELECT
        id_usuario,
        'acciones' AS tipo,
        SUM(valor_actual) AS total_valor
    FROM
        cartera_acciones
    GROUP BY
        id_usuario

    UNION ALL

    SELECT
        id_usuario,
        'bonos' AS tipo,
        SUM(valor_actual) AS total_valor
    FROM
        cartera_bonos
    GROUP BY
        id_usuario

    UNION ALL

    SELECT
        id_usuario,
        'depositos' AS tipo,
        SUM(valor_actual) AS total_valor
    FROM
        cartera_depositos
    GROUP BY
        id_usuario
),

total_cartera AS (
    SELECT
        id_usuario,
        SUM(total_valor) AS total_cartera_valor
    FROM
        total_activos
    GROUP BY
        id_usuario
)

SELECT
    ta.id_usuario,
    ta.tipo,
    ta.total_valor,
    tc.total_cartera_valor,
    ROUND((ta.total_valor / tc.total_cartera_valor) * 100, 2) AS porcentaje
FROM
    total_activos ta
JOIN
    total_cartera tc ON ta.id_usuario = tc.id_usuario
ORDER BY
    ta.id_usuario, ta.tipo;


-- 15. Mostrar un ranking de usuarios por el valor total de sus activos, incluyendo el desglose por tipo de activo.

WITH total_activos AS (
    SELECT
        id_usuario,
        'acciones' AS tipo,
        SUM(valor_actual) AS total_valor
    FROM
        cartera_acciones
    GROUP BY
        id_usuario

    UNION ALL

    SELECT
        id_usuario,
        'bonos' AS tipo,
        SUM(valor_actual) AS total_valor
    FROM
        cartera_bonos
    GROUP BY
        id_usuario

    UNION ALL

    SELECT
        id_usuario,
        'depositos' AS tipo,
        SUM(valor_actual) AS total_valor
    FROM
        cartera_depositos
    GROUP BY
        id_usuario
),

total_cartera AS (
    SELECT
        id_usuario,
        SUM(total_valor) AS total_cartera_valor
    FROM
        total_activos
    GROUP BY
        id_usuario
)

SELECT
    ta.id_usuario,
    u.nombre,
    ta.tipo,
    ta.total_valor,
    tc.total_cartera_valor
FROM
    total_activos ta
JOIN
    total_cartera tc ON ta.id_usuario = tc.id_usuario
JOIN
    usuarios u ON ta.id_usuario = u.NIF_CIF
ORDER BY
    tc.total_cartera_valor DESC, ta.id_usuario, ta.tipo;


-- NIVEL 4 - CONSULTAS COMPLEJAS

-- 16. Crear un informe que muestre, para cada usuario, sus 3 activos con mejor rendimiento y sus 3 activos con peor rendimiento en el último trimestre.

WITH rendimiento_trimestre AS (
    SELECT
        o.id_usuario,
        a.ent_emisora AS activo,
        a.valor_mercado AS precio_actual,
        o.precio AS precio_compra,
        o.fecha_op AS fecha_compra,
        ((a.valor_mercado - o.precio) / o.precio) * 100 AS rendimiento_pct,
        ROW_NUMBER() OVER(PARTITION BY o.id_usuario ORDER BY ((a.valor_mercado - o.precio) / o.precio) DESC) AS rank_mejor,
        ROW_NUMBER() OVER(PARTITION BY o.id_usuario ORDER BY ((a.valor_mercado - o.precio) / o.precio) ASC) AS rank_peor
    FROM
        operaciones o
    JOIN
        acciones a ON o.id_activo = a.id_activo
    WHERE
        o.tipo_operacion = 'compra'
        AND o.fecha_op >= CURRENT_DATE - INTERVAL '3 months'
        AND o.fecha_op <= CURRENT_DATE
)

SELECT
    id_usuario,
    'Mejor Rendimiento' AS tipo_rendimiento,
    activo,
    precio_actual,
    precio_compra,
    rendimiento_pct
FROM
    rendimiento_trimestre
WHERE
    rank_mejor <= 3

UNION ALL

SELECT
    id_usuario,
    'Peor Rendimiento' AS tipo_rendimiento,
    activo,
    precio_actual,
    precio_compra,
    rendimiento_pct
FROM
    rendimiento_trimestre
WHERE
    rank_peor <= 3
ORDER BY
    id_usuario, tipo_rendimiento, rendimiento_pct DESC;


-- 17. Encontrar patrones de inversión similares entre usuarios basados en la composición de sus carteras.

WITH total_activos AS (
    SELECT
        id_usuario,
        'acciones' AS tipo,
        SUM(valor_actual) AS total_valor
    FROM
        cartera_acciones
    GROUP BY
        id_usuario

    UNION ALL

    SELECT
        id_usuario,
        'bonos' AS tipo,
        SUM(valor_actual) AS total_valor
    FROM
        cartera_bonos
    GROUP BY
        id_usuario

    UNION ALL

    SELECT
        id_usuario,
        'depositos' AS tipo,
        SUM(valor_actual) AS total_valor
    FROM
        cartera_depositos
    GROUP BY
        id_usuario
),

total_cartera AS (
    SELECT
        id_usuario,
        SUM(total_valor) AS total_cartera_valor
    FROM
        total_activos
    GROUP BY
        id_usuario
),

diferencias_porcentaje AS (
    SELECT
        ta1.id_usuario AS usuario1,
        ta2.id_usuario AS usuario2,
        ROUND(ABS((ta1.total_valor / tc1.total_cartera_valor) - (ta2.total_valor / tc2.total_cartera_valor)) * 100, 2) AS diferencia_porcentaje
    FROM
        total_activos ta1
    JOIN
        total_cartera tc1 ON ta1.id_usuario = tc1.id_usuario
    JOIN
        total_activos ta2 ON ta1.tipo = ta2.tipo AND ta1.id_usuario < ta2.id_usuario
    JOIN
        total_cartera tc2 ON ta2.id_usuario = tc2.id_usuario
    ORDER BY
        diferencia_porcentaje
    LIMIT 1  -- Limitar a una sola fila con la menor diferencia porcentual
),

composicion_cartera AS (
    SELECT
        ta.id_usuario,
        ta.tipo,
        ROUND((ta.total_valor / tc.total_cartera_valor) * 100, 2) AS porcentaje
    FROM
        total_activos ta
    JOIN
        total_cartera tc ON ta.id_usuario = tc.id_usuario
)

SELECT
    dp.usuario1,
    cc1.tipo AS tipo_usuario1,
    cc1.porcentaje AS porcentaje_usuario1,
    dp.usuario2,
    cc2.tipo AS tipo_usuario2,
    cc2.porcentaje AS porcentaje_usuario2
FROM
    diferencias_porcentaje dp
JOIN
    composicion_cartera cc1 ON dp.usuario1 = cc1.id_usuario
JOIN
    composicion_cartera cc2 ON dp.usuario2 = cc2.id_usuario
    AND cc1.tipo = cc2.tipo
ORDER BY
    dp.diferencia_porcentaje;
