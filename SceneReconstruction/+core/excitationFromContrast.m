function excitationImage = excitationFromContrast(contrastImage, backgroundExcitation)
    [tmp, nCols, mRows] = ImageToCalFormat(contrastImage);
    for k = 1:size(tmp,1)
        tmp(k,:) = (1.0+tmp(k,:)) * backgroundExcitation(k);
    end
    excitationImage = CalFormatToImage(tmp, nCols, mRows);
end
