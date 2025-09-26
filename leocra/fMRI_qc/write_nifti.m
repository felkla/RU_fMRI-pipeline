function write_nifti(data, Vref, outFile)
    Vout = Vref;
    Vout.fname = outFile;
    spm_write_vol(Vout, data);
end