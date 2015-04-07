function compile_split_complex()


COMPLEX_CROSS_CORRELATION_PLANE = coder.typeof(1.00 + 1i, [inf, inf]);

% Set up the coder configuration
cfg = coder.config('mex');
cfg.DynamicMemoryAllocation = 'AllVariableSizeArrays';
cfg.GenerateReport = true;

% Run coder to generate the mex file.
codegen -config cfg splitComplex -args {COMPLEX_CROSS_CORRELATION_PLANE};

end
