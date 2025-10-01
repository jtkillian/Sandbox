function run_ci()
% RUN_CI  MATLAB CI entrypoint (safe on blank repos).
% - Creates src/ and tests/ if missing
% - Runs tests (if any) and writes JUnit + Cobertura reports
% - Empty test suite => green (success)

import matlab.unittest.TestRunner
import matlab.unittest.TestSuite
import matlab.unittest.plugins.XMLPlugin
import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.codecoverage.CoberturaFormat

root = pwd;
srcDir   = fullfile(root, 'src');
testsDir = fullfile(root, 'tests');

% Ensure project structure exists so CI never dies on first run
ensureDir(srcDir);
ensureDir(testsDir);
ensureDir(fullfile(root,'test-results'));
ensureDir(fullfile(root,'code-coverage'));

% Add paths only if folders exist (they do now, but keep explicit)
if isfolder(srcDir)
    addpath(genpath(srcDir));
end
if isfolder(testsDir)
    addpath(genpath(testsDir));
end

junitFile = fullfile(root,'test-results','results.xml');
covFile   = fullfile(root,'code-coverage','coverage.xml');

% Build suite only if tests folder contains .m files
hasTests = isfolder(testsDir) && ~isempty(dir(fullfile(testsDir, '**', '*.m')));

if ~hasTests
    % No tests present -> write minimal dummy reports and return success
    writeEmptyJUnit(junitFile);
    writeEmptyCobertura(covFile);
    fprintf('[run_ci] No tests found in "%s". Wrote empty reports. Treating as PASS.\n', testsDir);
    return
end

% Runner + plugins
runner = TestRunner.withNoPlugins;
runner.addPlugin(XMLPlugin.producingJUnitFormat(junitFile));

% Only add coverage if src exists (it should)
if isfolder(srcDir)
    covFmt = CoberturaFormat(covFile);
    runner.addPlugin(CodeCoveragePlugin.forFolder(srcDir, ...
        'IncludingSubfolders', true, 'Producing', covFmt));
else
    % Still create an empty coverage file to keep CI readers happy
    writeEmptyCobertura(covFile);
end

% Discover & run
suite = TestSuite.fromFolder(testsDir, 'IncludingSubfolders', true);
if isempty(suite)
    % Folder exists but no discoverable tests
    writeEmptyJUnit(junitFile);
    writeEmptyCobertura(covFile);
    fprintf('[run_ci] tests/ exists but suite is empty. Treating as PASS.\n');
    return
end

results = runner.run(suite);

% Fail the CI only if any test failed
failed = any([results.Failed]);
if failed
    error('[run_ci] Unit tests failed. See %s', junitFile);
end
end

function ensureDir(p)
if ~isfolder(p)
    mkdir(p);
    % drop a .gitkeep so the folder stays in the repo when committed
    try
        k = fullfile(p,'.gitkeep');
        if exist(k, 'file') ~= 2
            fid = fopen(k, 'w');
            if fid > 0
                fclose(fid);
            end
        end
    catch
    end
end
end

function writeEmptyJUnit(outfile)
% Minimal JUnit XML that parsers accept (0 tests)
ensureDir(fileparts(outfile));
fid = fopen(outfile,'w');
assert(fid>0, 'Cannot write %s', outfile);
fprintf(fid, ['<?xml version="1.0" encoding="UTF-8"?>\n' ...
    '<testsuites tests="0" failures="0" errors="0" time="0">\n' ...
    '  <testsuite name="MATLAB" tests="0" failures="0" errors="0" time="0"/>\n' ...
    '</testsuites>\n']);
fclose(fid);
end

function writeEmptyCobertura(outfile)
% Minimal Cobertura XML with zero coverage
ensureDir(fileparts(outfile));
fid = fopen(outfile,'w');
assert(fid>0, 'Cannot write %s', outfile);
ts = string(datetime('now', 'Format', 'yyyy-MM-ddTHH:mm:ss'));
fprintf(fid, ['<?xml version="1.0" ?>\n' ...
    '<!DOCTYPE coverage SYSTEM "http://cobertura.sourceforge.net/xml/coverage-04.dtd">\n' ...
    '<coverage line-rate="0" branch-rate="0" version="MATLAB-CI" timestamp="%s" lines-valid="0" lines-covered="0">\n' ...
    '  <sources/>\n' ...
    '  <packages/>\n' ...
    '</coverage>\n'], ts);
fclose(fid);
end
