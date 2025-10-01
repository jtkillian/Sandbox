% run_ci.m
function run_ci
root = pwd;
addpath(genpath(fullfile(root,'src')));
addpath(genpath(fullfile(root,'tests')));

% Static analysis: fail on 'error'
issues = checkcode(fullfile(root,'src'),'-cyc','-id');
if ~isempty(issues) && any(strcmp({issues.severity},'error'))
    error('CI:Analyzer','MATLAB Code Analyzer found errors.');
end

% Unit tests + coverage + JUnit
import matlab.unittest.TestRunner
import matlab.unittest.plugins.XMLPlugin
import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.codecoverage.CoberturaFormat

suite  = testsuite('tests','IncludeSubfolders',true);
runner = TestRunner.withTextOutput('OutputDetail',1);

covDir = fullfile(root,'code-coverage'); if ~exist(covDir,'dir'), mkdir(covDir); end
runner.addPlugin(CodeCoveragePlugin.forFolder(fullfile(root,'src'), ...
    'Producing', CoberturaFormat(fullfile(covDir,'coverage.xml'))));

trDir = fullfile(root,'test-results'); if ~exist(trDir,'dir'), mkdir(trDir); end
runner.addPlugin(XMLPlugin.producingJUnit(fullfile(trDir,'results.xml')));

results = runner.run(suite);
assert(all([results.Passed]),'CI:TestsFailed','Some tests failed.');
end
