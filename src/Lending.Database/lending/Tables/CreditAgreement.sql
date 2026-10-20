CREATE TABLE [lending].[CreditAgreement]
(
    [CreditAgreementId] uniqueidentifier NOT NULL CONSTRAINT [DF_CreditAgreement_Id] DEFAULT NEWSEQUENTIALID(),
    [AgreementNumber] varchar(30) NOT NULL,
    [AccountId] uniqueidentifier NOT NULL,
    [CreditProductId] uniqueidentifier NOT NULL,
    -- Accepted terms are a snapshot, independent of later catalogue changes.
    [AgreementType] varchar(20) NOT NULL,
    [AgreedAmount] decimal(19,4) NOT NULL,
    [AnnualInterestRatePercent] decimal(9,6) NOT NULL,
    [TermMonths] int NULL,
    [Status] varchar(20) NOT NULL CONSTRAINT [DF_CreditAgreement_Status] DEFAULT 'Pending',
    [CreatedAtUtc] datetime2(7) NOT NULL CONSTRAINT [DF_CreditAgreement_Created] DEFAULT SYSUTCDATETIME(),
    [ActivatedAtUtc] datetime2(7) NULL,
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_CreditAgreement] PRIMARY KEY ([CreditAgreementId]),
    CONSTRAINT [UQ_CreditAgreement_Number] UNIQUE ([AgreementNumber]),
    CONSTRAINT [FK_CreditAgreement_Account] FOREIGN KEY ([AccountId]) REFERENCES [lending].[Account] ([AccountId]),
    CONSTRAINT [FK_CreditAgreement_Product] FOREIGN KEY ([CreditProductId]) REFERENCES [lending].[CreditProduct] ([CreditProductId]),
    CONSTRAINT [CK_CreditAgreement_Amount] CHECK ([AgreedAmount] > 0),
    CONSTRAINT [CK_CreditAgreement_Rate] CHECK ([AnnualInterestRatePercent] >= 0),
    CONSTRAINT [CK_CreditAgreement_Status] CHECK ([Status] IN ('Pending', 'Active', 'Settled', 'Cancelled')),
    CONSTRAINT [CK_CreditAgreement_Terms] CHECK
    (
        ([AgreementType] = 'FixedLoan' AND [TermMonths] IS NOT NULL AND [TermMonths] > 0)
        OR ([AgreementType] = 'RevolvingCredit' AND [TermMonths] IS NULL)
    ),
    CONSTRAINT [CK_CreditAgreement_Activation] CHECK
    (
        ([ActivatedAtUtc] IS NULL OR [ActivatedAtUtc] >= [CreatedAtUtc])
        AND ([Status] NOT IN ('Active', 'Settled') OR [ActivatedAtUtc] IS NOT NULL)
    )
);
