-- Stream heads also reserve business numbers independently of the rebuildable projection.
CREATE TABLE [lending].[AgreementStream]
(
    [CreditAgreementId] uniqueidentifier NOT NULL,
    [AgreementNumber] varchar(30) NOT NULL,
    [Version] bigint NOT NULL,
    CONSTRAINT [PK_AgreementStream] PRIMARY KEY ([CreditAgreementId]),
    CONSTRAINT [UQ_AgreementStream_Number] UNIQUE ([AgreementNumber]),
    CONSTRAINT [CK_AgreementStream_Version] CHECK ([Version] >= 1)
);
