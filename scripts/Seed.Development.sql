USE [Lending];
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. Customers
    INSERT INTO lending.Customer
        (CustomerNumber, FirstName, LastName, DateOfBirth, Email)
    SELECT
        v.CustomerNumber, v.FirstName, v.LastName,
        v.DateOfBirth, v.Email
    FROM (VALUES
        ('CUST-000001', N'Sophie', N'Turner',
         CONVERT(date, '19870412', 112), N'sophie.turner@example.com'),
        ('CUST-000002', N'Daniel', N'Clarke',
         CONVERT(date, '19910923', 112), N'daniel.clarke@example.com')
    ) AS v(CustomerNumber, FirstName, LastName, DateOfBirth, Email)
    WHERE NOT EXISTS (
        SELECT 1
        FROM lending.Customer AS c
        WHERE c.CustomerNumber = v.CustomerNumber
    );

    -- 2. Available credit products
    INSERT INTO lending.CreditProduct
        (ProductCode, ProductName, ProductType)
    SELECT v.ProductCode, v.ProductName, v.ProductType
    FROM (VALUES
        ('PERSONAL-LOAN', N'Personal Loan', 'FixedLoan'),
        ('FLEX-CREDIT', N'Flexible Credit', 'RevolvingCredit')
    ) AS v(ProductCode, ProductName, ProductType)
    WHERE NOT EXISTS (
        SELECT 1
        FROM lending.CreditProduct AS p
        WHERE p.ProductCode = v.ProductCode
    );

    -- 3. Accounts belonging to customers
    INSERT INTO lending.Account (CustomerId, AccountNumber)
    SELECT c.CustomerId, v.AccountNumber
    FROM (VALUES
        ('CUST-000001', 'ACC-000001'),
        ('CUST-000001', 'ACC-000002'),
        ('CUST-000002', 'ACC-000003')
    ) AS v(CustomerNumber, AccountNumber)
    JOIN lending.Customer AS c
        ON c.CustomerNumber = v.CustomerNumber
    WHERE NOT EXISTS (
        SELECT 1
        FROM lending.Account AS a
        WHERE a.AccountNumber = v.AccountNumber
    );

    -- 4. Accepted credit agreements
    INSERT INTO lending.CreditAgreement
    (
        AgreementNumber, AccountId, CreditProductId,
        AgreementType, AgreedAmount,
        AnnualInterestRatePercent, TermMonths,
        Status, ActivatedAtUtc
    )
    SELECT
        v.AgreementNumber, a.AccountId, p.CreditProductId,
        v.AgreementType, v.AgreedAmount,
        v.InterestRate, v.TermMonths,
        'Active', SYSUTCDATETIME()
    FROM (VALUES
        ('AGR-000001', 'ACC-000001', 'PERSONAL-LOAN',
         'FixedLoan', 12500.00, 7.90, 48),
        ('AGR-000002', 'ACC-000002', 'FLEX-CREDIT',
         'RevolvingCredit', 3000.00, 19.90, NULL),
        ('AGR-000003', 'ACC-000003', 'PERSONAL-LOAN',
         'FixedLoan', 8000.00, 8.50, 36)
    ) AS v
    (
        AgreementNumber, AccountNumber, ProductCode,
        AgreementType, AgreedAmount, InterestRate, TermMonths
    )
    JOIN lending.Account AS a
        ON a.AccountNumber = v.AccountNumber
    JOIN lending.CreditProduct AS p
        ON p.ProductCode = v.ProductCode
    WHERE NOT EXISTS (
        SELECT 1
        FROM lending.CreditAgreement AS ca
        WHERE ca.AgreementNumber = v.AgreementNumber
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;