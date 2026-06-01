-- =============================================
-- 온라인 쇼핑몰 데이터베이스 - 스키마 생성
-- DB: SQLite
-- =============================================

-- 기존 테이블이 있으면 삭제 (재실행 가능하도록)
DROP TABLE IF EXISTS order_item;
DROP TABLE IF EXISTS order_;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS member;

-- FK 제약조건 활성화 (SQLite 전용 설정)
PRAGMA foreign_keys = ON;

-- -----------------------------------------------
-- 1. 회원 테이블
-- -----------------------------------------------
CREATE TABLE member (
    member_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    name       VARCHAR(50)  NOT NULL,
    email      VARCHAR(100) NOT NULL UNIQUE,   -- UNIQUE 적용
    phone      VARCHAR(20),
    joined_at  DATE         NOT NULL DEFAULT (DATE('now'))
);

-- -----------------------------------------------
-- 2. 카테고리 테이블
-- -----------------------------------------------
CREATE TABLE category (
    category_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    category_name VARCHAR(50) NOT NULL UNIQUE  -- UNIQUE 적용
);

-- -----------------------------------------------
-- 3. 상품 테이블 (category와 1:N 관계)
-- -----------------------------------------------
CREATE TABLE product (
    product_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id  INTEGER      NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    price        INTEGER      NOT NULL CHECK (price >= 0),  -- 음수 방지
    stock        INTEGER      NOT NULL DEFAULT 0 CHECK (stock >= 0),
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);

-- -----------------------------------------------
-- 4. 주문 테이블 (member와 1:N 관계)
-- -----------------------------------------------
CREATE TABLE order_ (
    order_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    member_id   INTEGER NOT NULL,
    order_date  DATE    NOT NULL DEFAULT (DATE('now')),
    status      VARCHAR(20) NOT NULL DEFAULT 'pending',  -- pending / paid / shipped / cancelled
    total_price INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (member_id) REFERENCES member(member_id)
);

-- -----------------------------------------------
-- 5. 주문상세 테이블 (order_ 및 product와 1:N 관계)
-- -----------------------------------------------
CREATE TABLE order_item (
    item_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id    INTEGER NOT NULL,
    product_id  INTEGER NOT NULL,
    quantity    INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price  INTEGER NOT NULL,  -- 주문 시점 단가 저장
    FOREIGN KEY (order_id)   REFERENCES order_(order_id),
    FOREIGN KEY (product_id) REFERENCES product(product_id)
);

-- -----------------------------------------------
-- 인덱스 생성
-- 적용 이유: order_ 테이블에서 member_id로 주문 조회가 잦으므로
--           인덱스를 걸어 조회 속도를 개선한다.
-- -----------------------------------------------
CREATE INDEX idx_order_member ON order_(member_id);

-- 상품 조회 시 카테고리 필터링이 자주 발생하므로 인덱스 추가
CREATE INDEX idx_product_category ON product(category_id);
