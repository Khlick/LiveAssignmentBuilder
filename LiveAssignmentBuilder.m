function LiveAssignmentBuilder(inputFile,opts)
% LiveAssignmentBuilder  Generate MATLAB live scripts for assignments and answer keys.
%
%   LiveAssignmentBuilder(inputFile, opts) converts MATLAB .m files into
%   live scripts (.mlx) for educational purposes, generating student worksheets
%   and instructor keys with custom parsing syntax to differentiate between
%   answer blocks and fill-in areas for students.
%
%   The function also allows creating a CONTENTS live script with links to
%   all generated live scripts and can package the outputs for distribution.
%
%   Inputs:
%   -------
%   inputFile : Repeating string arguments specifying the input .m files
%               to be parsed. If set to "none" or omitted, the function
%               will parse all .m files in the specified root directory.
%
%   opts : Structure of optional arguments with the following fields:
%
%       'root' (default: ".")        : Root directory where the input files are located.
%
%       'output' (default: ".")      : Directory where the output files will be saved.
%
%       'libs' (default: "")         : Path to additional libraries to include in the package.
%
%       'verbose' (default: false)   : If true, prints detailed progress and status messages.
%
%       'package' (default: false)   : If true, packages the generated outputs into a ZIP file.
%
%       'buildContents' (default: false) : If true, generates a CONTENTS live script with
%                                          links to all generated live scripts.
%
%       'executeKey' (default: false): If true, executes the generated key files to verify
%                                      their functionality.
%
%   Example:
%   --------
%   % Convert specific .m files into live scripts with default settings:
%   LiveAssignmentBuilder("file1.m", "file2.m");
%
%   % Convert .m files and specify output directory with verbosity:
%   LiveAssignmentBuilder("file1.m", "file2.m", ...
%       struct('output', 'output_directory', 'verbose', true));
%
%   % Automatically find and convert all .m files in the current directory:
%   LiveAssignmentBuilder("none");
%
%   Notes:
%   ------
%   If no files are provided, the function will search for and process all
%   .m files in the current working directory.
%
%   The custom parsing syntax includes:
%   - Sticky Blocks (%!): Mark sections as non-editable for students.
%   - Answer Blocks (%@): Instructor-only content hidden in the student version.
%   - Multiline Answer Blocks (%|@ ... %||@): Sections for student answers.
%   - Inline Answer Blocks (%<@ ... %>@): Inline expressions for student answers
%     or hidden solutions.
%
%   See also: matlab.internal.liveeditor.openAndSave, dir, mkdir, copyfile.
%   Version: 0.0.1
%   Author: Khris Griffis, Ph.D.
%   Year: 2024
%   License: MIT
%%%

  arguments (Repeating)
    inputFile (1,1) string
  end
  arguments
    opts.root (1,1) string = "."
    opts.output (1,1) string = "."
    opts.libs (1,1) string = ""
    opts.verbose (1,1) logical = false
    opts.package (1,1) logical = false
    opts.buildContents (1,1) logical= false
    opts.executeKey (1,1) logical = false
  end

  import matlab.internal.liveeditor.LiveEditorUtilities;

  if isempty(opts.root) || opts.root == ""
    root = ".";
  else
    root = opts.root;
  end
  mustBeFolder(root); % validate

  % Check for libs
  libDir = opts.libs;
  hasLibs = libDir ~= "";
  libTarget = "";
  if hasLibs
    mustBeFolder(libDir);
    libDir = dir(libDir).folder;
    [~,libTarget] = fileparts(libDir);
  end

  % Check Target directory
  target = opts.output;
  if target == "."
    [~,~] = mkdir(fullfile(target,"target"));
    target = fullfile(target,"target");
  elseif ~exist(target,"dir")
    [~,~] = mkdir(target);
  end
  % Verify
  mustBeFolder(target);

  if opts.package
    [~,~] = mkdir(fullfile(target,"_pkg"));
  end

  % parse inputs
  if isscalar(inputFile) && inputFile{1} == "none"
    inputFile = [];
  end
  if ~isempty(inputFile)
    fileList = fullfile(root,cat(2,inputFile{:}));
  else
    dirContents = dir(fullfile(root,'*.m'));
    fileList = string({dirContents.name});
    fileList(ismember(fileList,'BUILD.m')) = []; % drop build file
    fileList = fullfile(root,fileList);
  end

  % make sure all files exist
  nFiles = numel(fileList);
  validFiles = false(1,nFiles);
  for f = 1:nFiles
    fileList(f) = string(LiveEditorUtilities.resolveFileName(char(fileList(f))));
    validFiles(f) = exist(fileList(f),'file');
  end

  if ~any(validFiles), error('Could not locate input files.'); end

  % clear invalid files
  if opts.verbose && any(~validFiles)
    fprintf( ...
      "Skipping invalid files: %s.\n", ...
      strjoin(strcat("'",fileList(~validFiles),"'"),", ") ...
      );
  end
  fileList(~validFiles) = [];
  % update fileList
  nFiles = sum(validFiles);

  % setup output files
  [~,outputFiles,~] = fileparts(fileList);
  outputPaths = fullfile(target,outputFiles);

  % Set up package structure
  pkgTarget = "";
  if opts.package
    % Create package directory
    pkgTarget = fullfile(target,"_pkg");
    [~,~] = mkdir(pkgTarget);
  end

  % Copy libraries
  if hasLibs && exist(libDir,"dir")
    % copy to target
    copyfile(libDir,fullfile(target,libTarget));
    if opts.package
      % Also copy to pkg directory
      copyfile(libDir,pkgTarget);
    end
  end

  % Run the parser
  didParse = false(1,nFiles);
  for f = 1:nFiles
    if opts.verbose, fprintf("Parsing File: '%s'...",fileList(f)); end
    S = parseMToMlx( ...
      fileList(f), ...
      outputPaths(f), ...
      opts.executeKey ...
      );
    didParse(f) = S;
    if opts.verbose
      if S
        fprintf(" Success!\n");
      else
        fprintf(" Fail!\n");
      end
    end
  end

  % report success
  if opts.verbose,fprintf("\nDone Parsing!\n");end

  % build the contents live script
  if opts.buildContents || opts.package
    if opts.verbose, fprintf('Building CONTENTS.mlx...');end
    makeContents(root);
    if opts.verbose, fprintf(' Done!\n');end
  end

  % determine if the build should be packaged
  if ~opts.package
    % cleanup
    if opts.verbose
      fprintf("Build Complete!\n");
    end
    return
  end

  if opts.verbose
    fprintf("Packaging... ");
  end
  makePackage(root);
  if opts.verbose
    fprintf("Done!\n\nBuild Complete!\n");
  end
end

%% CONTENTS
function makeContents(root)
  % idea: group name is printed as section header: case insensitive detection
  % Name (key): Title Header
  %  Description...
  % parse _pkg folder for files
  mlxFiles = getMLX(root,"_pkg");
  mlxFiles = string(mlxFiles)';
  mlxFiles(contains(mlxFiles,"CONTENTS.mlx")) = [];
  [~,mlxNames,~] = fileparts(mlxFiles);
  % drop KEY names as we will assume if a file exists so does the _key version
  isKeyName = endsWith(mlxNames,"_key");
  mlxNames(isKeyName) = [];
  % Cursory organization
  [~,sortOrder] = sort(mlxNames); % sort by type
  mlxNames = mlxNames(sortOrder);
  % Split names to determine final order
  splitNames = arrayfun(@(n)strsplit(n,"_"),mlxNames,'unif',0);
  % each split should have 3 parts
  isCmpl = cellfun(@(s)numel(s)==3,splitNames);
  splitIdOrder = cellfun(@(s)str2double(s(2)),splitNames);

  % names that don't comply will be put at the end in no particular order
  nonconformedIdx = isnan(splitIdOrder) | ~isCmpl;
  nonconformedNames = mlxNames(nonconformedIdx);

  % drop noncompliant files
  splitIdOrder(nonconformedIdx) = [];
  mlxNames(nonconformedIdx) = [];
  splitNames(nonconformedIdx) = [];

  % organize grouped splits
  groups = cellfun(@(s)s(1),splitNames);
  groupId = unique(groups,'stable');

  introIdx = groups == "Introduction";
  introLoc = groupId == "Introduction";

  % organize Intro First
  mlxNames = [mlxNames(introIdx);mlxNames(~introIdx)];
  splitNames = [splitNames(introIdx);splitNames(~introIdx)];
  splitIdOrder = [splitIdOrder(introIdx);splitIdOrder(~introIdx)];
  groupId = [groupId(introLoc);groupId(~introLoc)];
  groups = [groups(introIdx);groups(~introIdx)];

  % initialize struct holder
  cats(1:numel(groupId),1) = struct('Category',"",'Paths',"",'Files',"",'Names',"",'Titles',"",'Descriptions',"");

  % Group by internal Id
  for g = 1:numel(groupId)
    gId = groupId(g);
    gX = ismember(groups,gId);
    gF = mlxNames(gX);
    gS = splitNames(gX);
    gN = cellfun(@(s)s(3),gS); % titles
    gOrder = splitIdOrder(gX);
    [~,sOrd] = sort(gOrder);

    cats(g).Category = gId;
    cats(g).Paths = strcat(gF(sOrd),".m");
    cats(g).Files = gF(sOrd);
    cats(g).Names = gN(sOrd);
    % titles and descriptions to be read later.
  end

  % merge noncompliant names on bottom with category: Other
  if any(nonconformedIdx)
    cats(end+1) = struct( ...
      'Category',"Other", ...
      'Paths', strcat(nonconformedNames,".m"), ...
      'Names', nonconformedNames, ...
      'Files', nonconformedNames, ...
      'Titles',"", ...
      'Descriptions',"" ...
      );
  end

  nC = numel(cats);
  for c = 1:nC
    this = cats(c);
    nF = numel(this.Files);
    for f = 1:nF
      fn = this.Paths(f);
      fCnt = fileread(fn);
      fCnt = string(strsplit(fCnt,"\n"))';
      % find first %% for Title, should be first line
      titleStart = find(startsWith(fCnt,"%% "),1,'first');
      titleEnd = find(startsWith(fCnt((titleStart+1):end),"% "),1,'first') + titleStart;
      descEnd = find(startsWith(fCnt((titleEnd+1):end),"%%"),1,'first') + titleEnd;
      ttl = strtrim(regexprep(fCnt(titleStart:(titleEnd-1)), '%',''));
      ttl(ttl == "") = [];
      this.Titles(f) = strjoin(ttl," ");
      desc = strtrim(regexprep(fCnt(titleEnd:(descEnd-1)), '%',''));
      desc(desc == "") = [];
      this.Descriptions(f) = strjoin(desc," ");
    end
    cats(c) = this;
  end


  % write the contents.m file
  tmpOut = fullfile(root,"_pkg","CONTENTS.m");
  fid = fopen(tmpOut,'wt');
  fprintf(fid,"%%%% Contents\n%% \n");
  for c = 1:nC
    this = cats(c);
    fprintf(fid,"%%%%%% %s\n%% \n%% \n",this.Category);
    nF = numel(this.Files);
    for f = 1:nF
      fprintf( ...
        fid, ...
        "%% \n%s\n%% \n", ...
        tocEntry( ...
        this.Names(f), ...
        this.Titles(f), ...
        this.Files(f), ...
        this.Descriptions(f) ...
        ) ...
        );
    end
    fprintf(fid,"%% \n");
  end

  % add contents
  fclose(fid);
  pause(0.1);

  % convert to MLX
  matlab.internal.liveeditor.openAndSave(char(tmpOut),char(fullfile(root,"_pkg","CONTENTS.mlx")));
  pause(0.5);

  % remove temporary file
  delete(tmpOut);
end

%% PACKAGE
function makePackage(root)
  % package zip file
  tmpName = sprintf("MATLAB_Resources_%s",date);
  mkdir(tmpName);
  zipFile = strcat(tmpName,'.zip');
  % copy library files
  copyfile("lib",fullfile(tmpName,"lib"));
  % get packaged mlx files
  mlxFiles = getMLX(root,"_pkg");
  % copy to tmp folder
  arrayfun(@(f)copyfile(f,tmpName),mlxFiles);
  % zip folder
  zip(zipFile,tmpName);
  % cleanup
  movefile(zipFile,"releases");
  rmdir(tmpName,'s');

end

%% File Parser
function status = parseMToMlx(srcFile,dstFile,executeKey)
  arguments
    srcFile (1,:) char
    dstFile (1,:) char
    executeKey (1,1) logical = true
  end
  import matlab.internal.liveeditor.openAndSave;


  status = false;

  % parse file parts
  [~,srcName,srcExt] = fileparts(srcFile);

  %
  if ~strcmp(srcExt,'.m'), return; end

  try
    if isScriptFile(srcFile)
      % Handle as a script
      fprintf("'%s' is identified as a script.\n", srcFile);
    else
      % Handle as a function
      fprintf("'%s' is identified as a function.\n", srcFile);
    end
  catch ME
    fprintf(2, "Error checking script/function status for '%s': '%s'\n", srcFile, ME.message);
    return;
  end


  % parse code file
  sourceCode = readlines(srcFile);
  stringCode = string(sourceCode);


  % Parse sticky blocks: %!
  % This just requires a quick switch of code, no parsing needed
  stickyBlocks = ~cellfun(@isempty, regexp(stringCode, '^%!', 'once'), 'unif', 1);
  stringCode(stickyBlocks) = "% DO NOT EDIT THE FOLLOWING";
  
  %Parse special syntax for answer blocks: %@
  answerBlockStarts = find(~cellfun(@isempty,regexp(stringCode,'^%@','once'),'unif',1));
  answerBlocks = sort(answerBlockStarts(:))+1; % make sure the ANSWER HERE gets displayed
  answerBlocks(:,2) = 0;
  for p = 1:size(answerBlocks,1)
    startIdx = answerBlocks(p,1);
    chunk = stringCode(startIdx:end);
    % find
    pStop = ~cellfun(@isempty,regexp(chunk,'^%!','once'),'unif',1);
    cStop = ~cellfun(@isempty,regexp(chunk,'^%{2,}','once'),'unif',1);
    stopIdx = find(pStop | cStop, 1, 'first') + startIdx-2;
    if isempty(stopIdx)
      stopIdx = numel(stringCode);
    end
    answerBlocks(p,2) = stopIdx;
  end

  % Convert answer blocks
  stringCode(answerBlockStarts) = "% ANSWER BELOW";
  % Get answer block locations
  nAnswerBlocks = size(answerBlocks,1);
  answerIndices = cell(nAnswerBlocks,1);
  for a = 1:nAnswerBlocks
    answerIndices{a} = (answerBlocks(a,1):answerBlocks(a,2)).';
  end
  answerIndices = unique(cat(1,answerIndices{:}));
  
  % split key and worksheet here
  codes = struct();
  codes.key = stringCode;
  % Drop answer blocks from the worksheet.
  stringCode(answerIndices) = [];
  codes.work = stringCode;

  % write plain code to a temporary file and then use openAndSave to convert m-file
  % to mlx-file
  tmpOut = dstFile + "_tmp.m";
  
  % parse code for output types, then convert to mlx
  codenames = ["key","work"];
  for cname = codenames
    thiscode = codes.(cname);

    % Parse multiline start/end blocks: %|@ ... %||@
    mlStartBlocks = find(~cellfun(@isempty, regexp(thiscode, '%\|@', 'once'), 'unif', 1));
    mlBlocks = sort(mlStartBlocks(:))+1;
    mlBlocks(:,2) = mlBlocks(:);
    for p = 1:numel(mlStartBlocks)
      startIdx = mlStartBlocks(p);
      lineContent = regexprep(thiscode(startIdx),"%\|@","~~~");
      if startsWith(strtrim(lineContent),"%")
        mlStartBlocks(p) = -1;
        mlBlocks(p,:) = -1;
        continue
      end
      chunk = thiscode(startIdx:end);
      pStop = ~cellfun(@isempty,regexp(chunk,'%\|\|@','once'),'unif',1);
      cStop = ~cellfun(@isempty,regexp(chunk,'^%{2,}','once'),'unif',1);
      stopIdx = find(pStop | cStop, 1, 'first') + startIdx-2;
      if isempty(stopIdx)
        stopIdx = numel(stringCode);
      end
      mlBlocks(p,2) = stopIdx;
    end
    mlBlocks(mlBlocks(:,1) == -1, :) = [];
    mlStartBlocks(mlStartBlocks == -1) = [];
    mlEndBlocks = mlBlocks(:,2) + 1;
    %  Replace marks
    thiscode(mlStartBlocks) = regexprep(thiscode(mlStartBlocks),"%\|@", "%--- Answer Start ---|");
    thiscode(mlEndBlocks) = regexprep(thiscode(mlEndBlocks),"%\|\|@", "%--- Answer End ---|");
    
    % Drop if worksheet
    if cname == "work"
      nML = size(mlBlocks,1);
      mlInds = cell(nML,1);
      for a = 1:nML
        mlInds{a} = (mlBlocks(a,1):mlBlocks(a,2)).';
      end
      mlInds = unique(cat(1,mlInds{:}));
      thiscode(mlInds) = [];
    end

    % Parse inline answer blocks: %<@ ... %>@
    ilBlocks = find(~cellfun(@isempty, regexp(thiscode,"%<@",'once'), 'unif', 1));
    % read until eol or until %>@
    for p = 1:length(ilBlocks)
      idx = ilBlocks(p);
      lineContent = regexprep(thiscode(idx),"%<@","~~~");
      if startsWith(strtrim(lineContent),"%")
        continue
      end
      if cname == "work"
        thiscode(idx) = regexprep(thiscode(idx), '%<@([^%]*)%>@', '"%--- ANSWER ---%"') + " % replace string with valid answer";
      else
        thiscode(idx) = regexprep(thiscode(idx), '%<@([^%]*)%>@', '$1') + " % inline answer";
      end
    end

    % write temp file for parsing
    fid = fopen(tmpOut,'wt');
    if fid < 0, error('Error creating temporary file, check rights.'); end
    for row = 1:numel(thiscode)
      fprintf(fid,'%s\n',thiscode(row));
    end
    fclose(fid);
    pause(0.5);

    % parse temp file
    if cname == "work"
      outname = dstFile + ".mlx";
    else
      outname = dstFile + "_key.mlx";
    end
    openAndSave(char(tmpOut),char(outname));
    pause(0.5);

  end  

  % Run and save the key file
  if executeKey
    try
      matlab.internal.liveeditor.executeAndSave(char(dstFile + "_key.mlx"));
    catch me
      fprintf( ...
        "Error Parsing Key '%s' with message: '%s'.\nCheck the output.\n", ...
        dstFile + "_key.mlx", ...
        sprintf("%s - '%s'",me.identifier,me.message) ...
        );
    end
    pause(0.05);
    evalin('base','clearvars');
  end

  % remove the tmp file and lib
  delete(tmpOut);

  % report success
  status = true;
end

%% Helper Functions

function mlxFiles = getMLX(root,sub)
  arguments
    root (1,1) string
  end
  arguments (Repeating)
    sub (1,1) string
  end
  pkgContents = dir(fullfile(root,sub{:},"*.mlx"));
  mlxFiles = fullfile(string({pkgContents.folder}),string({pkgContents.name}));
end

function str = tocEntry(name,title,file,desc)
  arguments
    name (1,1) string
    title (1,1) string
    file (1,1) string
    desc (1,1) string
  end
  str = sprintf( ...
    "%% # <./%s.mlx %s> (<./%s_key.mlx key>): *%s.* %s", ...
    file, ...
    name, ...
    file, ...
    title, ...
    desc ...
    );
end

function isScript = isScriptFile(fileName)
  % Initialize as true, assume it's a script
  isScript = true;

  % Open the file
  fid = fopen(fileName, 'rt');
  if fid < 0
    error("Error opening file: %s", fileName);
  end

  % Read the first few lines of the file
  linesToCheck = 10;  % Number of lines to check at the start
  lines = strings(1, linesToCheck);
  for i = 1:linesToCheck
    line = fgetl(fid);
    if ischar(line)
      lines(i) = strtrim(line);  % Trim whitespace for accurate checks
    else
      break;  % End of file reached
    end
  end
  fclose(fid);

  % Check if any line starts with 'function'
  functionPattern = '^function\s';
  isFunction = any(~cellfun(@isempty, regexp(lines, functionPattern, 'once')));

  % If a function declaration is found, it's not a script
  if isFunction
    isScript = false;
  end
end

