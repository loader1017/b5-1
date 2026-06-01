-- =============================================
-- 온라인 쇼핑몰 데이터베이스 - 핵심 쿼리 15개
-- ※ 반드시 01_schema.sql → 02_data.sql 순으로 실행 후 사용
-- =============================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- [기본 조회] 4개
-- ============================================================

-- Q1. 재고가 50개 이상인 상품 목록을 가격 내림차순으로 조회
-- 확인 내용: WHERE + ORDER BY 기본 사용
SELECT product_id, product_name, price, stock
FROM product
WHERE stock >= 50
ORDER BY price DESC;

-- Q2. 가장 최근에 가입한 회원 5명 조회
-- 확인 내용: ORDER BY + LIMIT 사용
SELECT member_id, name, email, joined_at
FROM member
ORDER BY joined_at DESC
LIMIT 5;

-- Q3. 'shipped' 상태인 주문 목록을 날짜 최신순으로 조회
-- 확인 내용: WHERE + ORDER BY 조합
SELECT order_id, member_id, order_date, status, total_price
FROM order_
WHERE status = 'shipped'
ORDER BY order_date DESC;

-- Q4. 상품명에 '세트' 또는 '프리미엄'이 포함된 상품 조회
-- 확인 내용: LIKE 패턴 매칭
SELECT product_id, product_name, price, stock
FROM product
WHERE product_name LIKE '%세트%'
   OR product_name LIKE '%프리미엄%';

-- ============================================================
-- [조인] 4개
-- ============================================================

-- Q5. 모든 주문에 회원 이름을 붙여서 조회 (INNER JOIN)
-- 확인 내용: order_ ↔ member 조인
SELECT o.order_id,
       m.name     AS 회원명,
       o.order_date,
       o.status,
       o.total_price
FROM order_ o
INNER JOIN member m ON o.member_id = m.member_id
ORDER BY o.order_date;

-- Q6. 주문상세에 상품명과 카테고리를 함께 조회 (INNER JOIN 3테이블)
-- 확인 내용: order_item ↔ product ↔ category 3중 조인
SELECT oi.item_id,
       oi.order_id,
       p.product_name  AS 상품명,
       c.category_name AS 카테고리,
       oi.quantity,
       oi.unit_price,
       (oi.quantity * oi.unit_price) AS 소계
FROM order_item oi
INNER JOIN product  p ON oi.product_id  = p.product_id
INNER JOIN category c ON p.category_id  = c.category_id
ORDER BY oi.order_id;

-- Q7. 한 번도 주문하지 않은 회원 목록 조회 (LEFT JOIN)
-- 확인 내용: LEFT JOIN + IS NULL 패턴으로 미주문 회원 추출
SELECT m.member_id,
       m.name,
       m.email,
       m.joined_at
FROM member m
LEFT JOIN order_ o ON m.member_id = o.member_id
WHERE o.order_id IS NULL;

-- Q8. 카테고리별 상품 목록 조회 (INNER JOIN)
-- 확인 내용: category ↔ product 조인 + ORDER BY 복합 정렬
SELECT c.category_name AS 카테고리,
       p.product_name  AS 상품명,
       p.price,
       p.stock
FROM product p
INNER JOIN category c ON p.category_id = c.category_id
ORDER BY c.category_name, p.price DESC;

-- ============================================================
-- [집계] 3개
-- ============================================================

-- Q9. 회원별 총 주문 횟수와 총 결제 금액 집계
-- 확인 내용: COUNT + SUM + GROUP BY
SELECT m.name        AS 회원명,
       COUNT(o.order_id)   AS 주문횟수,
       SUM(o.total_price)  AS 총결제금액
FROM member m
INNER JOIN order_ o ON m.member_id = o.member_id
GROUP BY m.member_id, m.name
ORDER BY 총결제금액 DESC;

-- Q10. 카테고리별 평균 상품 가격과 상품 수 조회
-- 확인 내용: AVG + COUNT + GROUP BY
SELECT c.category_name AS 카테고리,
       COUNT(p.product_id)  AS 상품수,
       AVG(p.price)         AS 평균가격
FROM category c
INNER JOIN product p ON c.category_id = p.category_id
GROUP BY c.category_id, c.category_name
ORDER BY 평균가격 DESC;

-- Q11. 2개 이상 주문된 상품만 조회 (HAVING 사용)
-- 확인 내용: GROUP BY + HAVING으로 집계 결과 필터링
SELECT p.product_name  AS 상품명,
       SUM(oi.quantity) AS 총판매수량,
       COUNT(DISTINCT oi.order_id) AS 주문건수
FROM order_item oi
INNER JOIN product p ON oi.product_id = p.product_id
GROUP BY oi.product_id, p.product_name
HAVING 주문건수 >= 2
ORDER BY 총판매수량 DESC;

-- ============================================================
-- [서브쿼리] 2개
-- ============================================================

-- Q12. 전체 상품 평균 가격보다 비싼 상품 목록 조회
-- 확인 내용: WHERE 절 서브쿼리
SELECT product_id,
       product_name,
       price
FROM product
WHERE price > (SELECT AVG(price) FROM product)
ORDER BY price DESC;

-- Q13. 한 번도 주문되지 않은 상품 목록 조회
-- 확인 내용: NOT IN 서브쿼리 (LEFT JOIN 방식과 비교)
SELECT product_id, product_name, price
FROM product
WHERE product_id NOT IN (
    SELECT DISTINCT product_id FROM order_item
);

-- ============================================================
-- [수정 및 삭제] 2개
-- ============================================================

-- Q14. 취소(cancelled) 상태 주문의 상품 재고를 원복
-- 확인 내용: UPDATE 문으로 데이터 수정
-- (주문 4번이 cancelled 상태 → 블루투스 스피커 1개 재고 원복)
UPDATE product
SET stock = stock + 1
WHERE product_id = (
    SELECT oi.product_id
    FROM order_item oi
    INNER JOIN order_ o ON oi.order_id = o.order_id
    WHERE o.order_id = 4 AND o.status = 'cancelled'
    LIMIT 1
);

-- 결과 확인: 블루투스 스피커(product_id=3) 재고가 81개가 되어야 함
SELECT product_id, product_name, stock FROM product WHERE product_id = 3;

-- Q15. 주문 상태를 'pending' → 'paid'로 업데이트 후 오래된 취소 주문 삭제
-- 확인 내용: UPDATE + DELETE 문

-- pending 주문 → paid로 변경
UPDATE order_
SET status = 'paid'
WHERE status = 'pending';

-- 2024년 1월 이전의 취소 주문 삭제
-- (먼저 주문상세를 지운 뒤 주문을 지워야 FK 오류 없음)
DELETE FROM order_item
WHERE order_id IN (
    SELECT order_id FROM order_
    WHERE status = 'cancelled' AND order_date < '2024-02-01'
);

DELETE FROM order_
WHERE status = 'cancelled' AND order_date < '2024-02-01';

-- 결과 확인: cancelled 주문이 없어야 함
SELECT order_id, status, order_date FROM order_ WHERE status = 'cancelled';

-- ============================================================
-- [보너스] 같은 요구를 JOIN vs 서브쿼리로 풀기
-- ============================================================

-- B1. 한 번도 주문 안 한 회원 - LEFT JOIN 방식
SELECT m.name FROM member m
LEFT JOIN order_ o ON m.member_id = o.member_id
WHERE o.order_id IS NULL;

-- B2. 한 번도 주문 안 한 회원 - 서브쿼리 방식
SELECT name FROM member
WHERE member_id NOT IN (SELECT DISTINCT member_id FROM order_);

-- → 결과는 동일. JOIN은 대용량에서 유리, 서브쿼리는 가독성이 좋음.
