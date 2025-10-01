function run_ci
%RUN_CI MATLAB CI entry point.
% - Discovers tests under tests/ and runs them.
% - Writes JUnit XML to test-results/results.xml
% - Writes Cobertura XML to code-coverage/coverage.xml
% - On empty repos or any exception, writes valid empty reports so CI never breaks.

root = pwd;
resultsDir   = fullfile(root, 'test-results');
coverageDir  = fullfile(root, 'code-coverage');
junitFile    = fullfile(resultsDir, 'results.xml');
covFile      = fullfile(coverageDir, 'coverage.xml');
srcDir       = fullfile(root, 'src');
testsDir     = fullfile(root, 'tests');

% Ensure dirs exist
mkdirIfMissing(resultsDir);
mkdirIfMissing(coverageDir);
mkdirIfMissing(srcDir);
mkdirIfMissing(testsDir);

% Add paths if present
if isfolder(srcDir), addpath(genpath(srcDir)); end
if isfolder(testsDir), addpath(genpath(testsDir)); end

import matlab.unittest.TestSuite
import matlab.unittest.TestRunner
import matlab.unittest.plugins.XMLPlugin
import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.codecoverage.CoberturaFormat

try

    % Discover tests (empty suite is okay)
    suite = TestSuite.fromFolder(testsDir, 'IncludingSubfolders', true);

    % Always create a runner and JUnit plugin so we get reports on any outcome
    runner = TestRunner.withTextOutput('Verbosity', 2);
    junitPlugin = XMLPlugin.producingJUnitFormat(junitFile);
    runner.addPlugin(junitPlugin);

    % Add coverage only if there are MATLAB files under src/
    if hasMFiles(srcDir)
        covPlugin = CodeCoveragePlugin.forFolder( ...
            srcDir, 'IncludingSubfolders', true, ...
            'Producing', CoberturaFormat(covFile));
        runner.addPlugin(covPlugin);
    else
        % No source files -> ensure an empty Cobertura exists
        writeEmptyCobertura(covFile);
    end

    if isempty(suite)
        % No tests discovered -> write empty JUnit and keep going
        writeEmptyJUnit(junitFile);
        return
    end

    % Run tests (JUnit written by plugin)
    runner.run(suite);

    % If coverage plugin wasn't attached (no src files), cov already written empty
    if ~isfile(covFile)
        writeEmptyCobertura(covFile);
    end

catch ME
    % On any failure, guarantee valid empty reports so the pipeline stays healthy
    try writeEmptyJUnit(junitFile); catch, end
    try writeEmptyCobertura(covFile); catch, end
    % Re-throw to let CI know run_ci had issues (the workflow step is continue-on-error)
    rethrow(ME)
end
end

% --- helpers ---
function mkdirIfMissing(d)
if ~isfolder(d), mkdir(d); end
end

function tf = hasMFiles(d)
tf = false;
if ~isfolder(d), return; end
S = dir(fullfile(d, '**', '*.m'));
tf = ~isempty(S);
end

function writeEmptyJUnit(p)
fid = fopen(p, 'w'); cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '<?xml version="1.0" encoding="UTF-8"?>\n');
fprintf(fid, '<testsuites tests="0" failures="0" errors="0" time="0">\n');
fprintf(fid, '  <testsuite name="MATLAB" tests="0" failures="0" errors="0" time="0"/>\n');
fprintf(fid, '</testsuites>\n');
end

function writeEmptyCobertura(p)
% Keep this minimal and static to avoid datetime formatting pitfalls on CI
fid = fopen(p, 'w'); cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '<?xml version="1.0" ?>\n');
fprintf(fid, '<!DOCTYPE coverage SYSTEM "http://cobertura.sourceforge.net/xml/coverage-04.dtd">\n');
fprintf(fid, ['<coverage line-rate="0" branch-rate="0" version="MATLAB-CI" ', ...
    'timestamp="0" lines-valid="0" lines-covered="0">\n']);
fprintf(fid, '  <sources/>\n');
fprintf(fid, '  <packages/>\n');
fprintf(fid, '</coverage>\n');
end
