function decodingSubDir = getDecodingSubDirectory(scansDir, decodingSubDir)
    decodingSubDir = fullfile(scansDir, decodingSubDir);
    if (exist(decodingSubDir, 'dir') == false)
        fprintf('\n%s folder does not exist. Will create it.\n', decodingSubDir);
        mkdir(decodingSubDir);
    else
        fprintf('\nFolder exists at %s.\n', decodingSubDir);
    end
end

