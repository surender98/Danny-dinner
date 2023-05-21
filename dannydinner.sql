/*
1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?
10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
*/

#Q1.What is the total amount each customer spent at the restaurant?
SELECT s.customer_id as Customer, SUM(m.price) as Amt_Spent
FROM sales s, menu m 
WHERE s.product_id = m.product_id
GROUP BY s.customer_id;

#Q2.How many days has each customer visited the restaurant?
SELECT customer_id AS Customer, COUNT(DISTINCT order_date) AS Visited 
FROM sales GROUP BY customer_id; 

#Q3.What was the first item from the menu purchased by each customer?
WITH cte AS (SELECT s.customer_id AS cust ,s.order_date ,m.product_name AS prd, 
DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS c_rank
FROM sales s LEFT JOIN menu m ON s.product_id = m.product_id)
SELECT cust,prd FROM cte WHERE c_rank = 1 GROUP BY cust,prd;

#Q4.What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name,COUNT(s.product_id) AS sold FROM sales s LEFT JOIN menu m ON s.product_id = m.product_id  
GROUP BY m.product_name ORDER BY sold DESC LIMIT 1;

#Q5.Which item was the most popular for each customer?
WITH cte AS (SELECT s.customer_id AS cust,m.product_name AS prd,COUNT(s.product_id) AS c,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS r
FROM sales s LEFT JOIN menu m on s.product_id = m.product_id GROUP BY s.customer_id,m.product_name)
SELECT cust,prd FROM cte WHERE r = 1;

#Q6.Which item was purchased first by the customer after they became a member?
WITH cte AS (
SELECT m.customer_id AS cust,m2.product_name AS prd,s.order_date AS od,
DENSE_RANK() OVER(PARTITION BY m.customer_id ORDER BY s.order_date) AS r 
FROM members m LEFT JOIN sales s ON m.customer_id  = s.customer_id 
LEFT JOIN menu m2 ON s.product_id  = m2.product_id
WHERE m.join_date > s.order_date
) 
SELECT cust,prd,od FROM cte WHERE r = 1;

#7.Which item was purchased just before the customer became a member?
WITH cte AS (
SELECT s.customer_id AS cust, m2.product_name AS prod, 
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS r,s.order_date AS dt
FROM sales s LEFT JOIN members m 
USING(customer_id) LEFT JOIN menu m2 USING(product_id)
WHERE m.join_date > s.order_date
)
SELECT cust,prod,dt FROM cte WHERE r = 1;

#8.What is the total items and amount spent for each member before they became a member?
SELECT m.customer_id,COUNT(s.product_id) AS Total_quantity, SUM(m2.price) AS Amount_spent  
FROM sales s LEFT JOIN members m USING(customer_id) LEFT JOIN menu m2 USING(product_id)
WHERE s.order_date  < m.join_date GROUP BY m.customer_id;

#9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier — 
#how many points would each customer have?
SELECT s.customer_id, SUM(CASE WHEN m.product_name = 'sushi' THEN m.price*20 ELSE m.price*10 END) AS Points 
FROM sales s LEFT JOIN menu m USING(product_id) GROUP BY s.customer_id;

#10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
#not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id, SUM(CASE WHEN m.product_name = "sushi" THEN m.price * 20 
WHEN s.order_date BETWEEN m2.join_date AND DATE_ADD(m2.join_date,INTERVAL 6 DAY) THEN m.price * 20 
ELSE m.price * 10 END) AS Points 
FROM sales s LEFT JOIN menu m USING(product_id) LEFT JOIN members m2 USING(customer_id)
WHERE s.order_date BETWEEN m2.join_date  AND "2021-01-31" AND s.customer_id  IN ("A","B")
GROUP BY s.customer_id;



