function scansDir = getScansDir(rootPath, configuration, adaptingFieldType, osType)

    if (strcmp(osType, 'biophysics-based'))
        osDir = 'BiophysOSresponses';
    else
        osDir = 'LinearOSresponses';
    end
    
    scansDir = sprintf('%s/ScansData.%sConfig/%s/%s', rootPath, configuration, adaptingFieldType, osDir);
    if (exist(scansDir, 'dir') == false)
        fprintf('\n%s folder does not exist. Will create it.\n', scansDir);
        mkdir(scansDir);
    else
        fprintf('\nFolder exists at %s.\n', scansDir);
    end

end
        