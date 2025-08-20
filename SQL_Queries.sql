create database manufacturing_sales;
create table manufacturing
(
    buyer VARCHAR(100),
    cust_code VARCHAR(50),
    cust_name VARCHAR(255),
    delivery_period VARCHAR(50),
    department_name VARCHAR(100),
    designer VARCHAR(10),
    doc_date DATE,
    doc_num VARCHAR(50),
    emp_code VARCHAR(20),
    emp_name VARCHAR(100),
    per_day_machine_cost DECIMAL(10,2),
    press_qty INT,
    processed_qty INT,
    produced_qty INT,
    rejected_qty INT,
    repeat_order INT,
    today_manufactured_qty INT,
    total_qty INT,
    total_value DECIMAL(12,2),
    wo_qty INT,
    machine_code VARCHAR(50),
    operation_name VARCHAR(100),
    operation_code VARCHAR(50),
    item_code VARCHAR(100),
    item_name TEXT
);
select * from manufacturing;


-- Total Produced Quantity --
SELECT 
    CONCAT(FORMAT(SUM(produced_qty) / 1000, 0), 'k') AS total_produced_quantity_k
FROM 
    manufacturing;


-- Rejection % --
SELECT 
    CONCAT(
        ROUND(
            (SUM(rejected_qty) / NULLIF(SUM(produced_qty), 0)) * 100, 
            2
        ), '%'
    ) AS rejection_rate_percent
FROM 
    manufacturing;


-- Total Manufactured Quantity --
SELECT 
    CONCAT(FORMAT(SUM(today_manufactured_qty) / 1000, 0), 'k') AS total_manufactured_quantity
FROM 
    manufacturing;


-- Average per day Machine Cost --
SELECT 
    AVG(per_day_machine_cost) AS avg_per_day_machine_cost
FROM 
    manufacturing;
    
    
-- Average per day Machine Cost By Customer --
SELECT cust_name, COUNT(*) AS repeat_orders
FROM manufacturing
WHERE repeat_order > 0
GROUP BY cust_name
ORDER BY repeat_orders DESC;


-- Average per day Machine Cost By Item --
SELECT item_name, COUNT(*) AS repeat_orders
FROM manufacturing
WHERE repeat_order > 0
GROUP BY item_name
ORDER BY repeat_orders DESC;


-- Employee Productivity--
SELECT 
    emp_code,
    emp_name,
    SUM(produced_qty) AS total_produced
FROM 
    manufacturing
GROUP BY 
    emp_code, emp_name
ORDER BY 
    total_produced DESC;
    
-- Department monthly production summary--
   CREATE VIEW department_monthly_production_summary AS
SELECT
    department_name AS DepartmentName,
    DATE_FORMAT(doc_date, '%Y-%m') AS YearMonth,
    SUM(produced_qty) AS TotalProduced,
    SUM(rejected_qty) AS TotalRejected,
    SUM(today_manufactured_qty) AS TotalTodayManufactured,
    SUM(total_qty) AS GrandTotalQty,
    SUM(total_value) AS GrandTotalValue,
    ROUND((SUM(rejected_qty) / NULLIF(SUM(produced_qty), 0)) * 100, 2) AS RejectionRatePercent
FROM manufacturing
GROUP BY 
    department_name, 
    DATE_FORMAT(doc_date, '%Y-%m');
    
    SELECT * 
FROM department_monthly_production_summary
ORDER BY YearMonth, DepartmentName;


-- Department-wise total production--
CREATE TABLE department_production_kpi (
    department_name VARCHAR(100) PRIMARY KEY,
    total_produced INT DEFAULT 0,
    total_rejected INT DEFAULT 0,
    rejection_rate DECIMAL(5,2) DEFAULT 0.00,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
INSERT INTO department_production_kpi (department_name, total_produced, total_rejected, rejection_rate)
SELECT
    department_name,
    SUM(produced_qty),
    SUM(rejected_qty),
    ROUND((SUM(rejected_qty) / NULLIF(SUM(produced_qty), 0)) * 100, 2)
FROM manufacturing
GROUP BY department_name;
DELIMITER //
CREATE TRIGGER department_kpi
AFTER INSERT ON manufacturing
FOR EACH ROW
BEGIN
    INSERT INTO department_production_kpi (department_name, total_produced, total_rejected, rejection_rate)
    VALUES (
        NEW.department_name,
        NEW.produced_qty,
        NEW.rejected_qty,
        ROUND((NEW.rejected_qty / NULLIF(NEW.produced_qty, 0)) * 100, 2)
    )
    ON DUPLICATE KEY UPDATE
        total_produced = total_produced + NEW.produced_qty,
        total_rejected = total_rejected + NEW.rejected_qty,
        rejection_rate = ROUND((total_rejected / NULLIF(total_produced, 0)) * 100, 2),
        last_updated = CURRENT_TIMESTAMP;
END;
//
DELIMITER ;


SELECT * 
FROM department_production_kpi
ORDER BY rejection_rate DESC;


-- Repeat Order Efficiency--
CREATE VIEW repeat_order_efficiency_view AS
SELECT 
    department_name,
    SUM(produced_qty) AS total_produced_repeat,
    SUM(rejected_qty) AS total_rejected_repeat,
    ROUND(
        ( (SUM(produced_qty) - SUM(rejected_qty)) / NULLIF(SUM(produced_qty), 0) ) * 100,
        2
    ) AS repeat_order_efficiency_percent
FROM manufacturing
WHERE repeat_order > 0
GROUP BY department_name;

SELECT * FROM repeat_order_efficiency_view;


-- On-Time Delivery Rate--
DELIMITER $$
CREATE PROCEDURE get_on_time_delivery_rate()
BEGIN
    SELECT 
        department_name,
        COUNT(CASE WHEN delivery_period = 'On Time' THEN 1 END) AS on_time_orders,
        COUNT(*) AS total_orders,
        ROUND(
            (COUNT(CASE WHEN delivery_period = 'On Time' THEN 1 END) / 
             NULLIF(COUNT(*), 0)) * 100,
            2
        ) AS on_time_delivery_rate_percent
    FROM manufacturing
    GROUP BY department_name;
END $$

DELIMITER ;

CALL get_on_time_delivery_rate();
