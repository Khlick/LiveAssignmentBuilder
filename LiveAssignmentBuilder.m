classdef LiveAssignmentBuilder
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
%   - Comment Blocks (%# ... %/#): Strips content from worksheets but preserves
%     comment text. In keys, converts to regular comments.
%%%
%   See also: matlab.internal.liveeditor.openAndSave, dir, mkdir, copyfile.
%
%   Version: 0.1.0
%   Author: Khris Griffis, Ph.D.
%   Year: 2024
%   License: MIT
%%%

  properties (Constant)
    % Version information
    Version = "0.1.0"
    Author = "Khris Griffis, Ph.D."
    Year = 2024
    License = "MIT"
  end
  properties (Access = private)
    workCode (:,1) string
    keyCode (:,1) string
    root (1,1) string
    output (1,1) string
    libs (1,1) string
    verbose (1,1) logical
    package (1,1) logical
    buildContents (1,1) logical
    executeKey (1,1) logical
    indentChar (1,:) char = " "
  end

  methods (Static)
    function version()
      % VERSION Display version information for LiveAssignmentBuilder
      %
      %   LiveAssignmentBuilder.version() displays the current version
      %   information including version number, author, year, and license.
      %
      %   See also LiveAssignmentBuilder, LiveAssignmentBuilder.help
      
      fprintf('LiveAssignmentBuilder Version %s\n', LiveAssignmentBuilder.Version);
      fprintf('Author: %s\n', LiveAssignmentBuilder.Author);
      fprintf('Year: %d\n', LiveAssignmentBuilder.Year);
      fprintf('License: %s\n', LiveAssignmentBuilder.License);
    end

    function help()
      % HELP Display help for LiveAssignmentBuilder
      %
      %   LiveAssignmentBuilder.help() displays the help documentation
      %   for the LiveAssignmentBuilder class, equivalent to calling
      %   doc LiveAssignmentBuilder.
      %
      %   See also LiveAssignmentBuilder, LiveAssignmentBuilder.version, doc
      
      doc('LiveAssignmentBuilder');
    end

    function syntax()
      % SYNTAX Display syntax information for LiveAssignmentBuilder
      %
      %   LiveAssignmentBuilder.syntax() displays the syntax and usage
      %   examples for the LiveAssignmentBuilder class.
      %
      %   See also LiveAssignmentBuilder, LiveAssignmentBuilder.help
      
      fprintf('LiveAssignmentBuilder Syntax:\n\n');
      fprintf('  obj = LiveAssignmentBuilder(inputFile, opts)\n\n');
      fprintf('Inputs:\n');
      fprintf('  inputFile - String or array of strings specifying input .m files\n');
      fprintf('  opts      - Structure with optional parameters:\n');
      fprintf('    .root         - Root directory (default: ".")\n');
      fprintf('    .output       - Output directory (default: ".")\n');
      fprintf('    .libs         - Path to additional libraries (default: "")\n');
      fprintf('    .verbose      - Print detailed messages (default: false)\n');
      fprintf('    .package      - Package outputs into ZIP (default: false)\n');
      fprintf('    .buildContents- Generate CONTENTS live script (default: false)\n');
      fprintf('    .executeKey   - Execute key files (default: false)\n\n');
      fprintf('Examples:\n');
      fprintf('  LiveAssignmentBuilder("file1.m", "file2.m")\n');
      fprintf('  LiveAssignmentBuilder("none", struct(''verbose'', true))\n');
      fprintf('  LiveAssignmentBuilder("task.m", struct(''output'', ''./out'', ''package'', true))\n\n');
    end

    function examples()
      % EXAMPLES Display usage examples for LiveAssignmentBuilder
      %
      %   LiveAssignmentBuilder.examples() displays detailed usage examples
      %   and parsing syntax for the LiveAssignmentBuilder class.
      %
      %   See also LiveAssignmentBuilder, LiveAssignmentBuilder.help
      
      fprintf('LiveAssignmentBuilder Examples:\n\n');
      
      fprintf('1. Basic Usage:\n');
      fprintf('   LiveAssignmentBuilder("file1.m", "file2.m")\n\n');
      
      fprintf('2. With Options:\n');
      fprintf('   LiveAssignmentBuilder("task.m", struct(''verbose'', true, ''package'', true))\n\n');
      
      fprintf('3. Parse All Files in Directory:\n');
      fprintf('   LiveAssignmentBuilder("none")\n\n');
      
      fprintf('Custom Parsing Syntax:\n');
      fprintf('  %% Sticky Blocks (%%!): Non-editable sections\n');
      fprintf('  %% Answer Blocks (%%@): Instructor-only content\n');
      fprintf('  %% Multiline Answer Blocks (%%|@ ... %%||@): Student answer areas\n');
      fprintf('  %% Inline Answer Blocks (%%<@ ... %%>@): Inline expressions\n');
      fprintf('  %% Comment Blocks (%%# ... %%/#): Strip content, preserve comments\n\n');
      
      fprintf('Example with Comment Blocks:\n');
      fprintf('  %% Regular code that students see\n');
      fprintf('  %%# This comment will be preserved\n');
      fprintf('  %%# Setup code hidden from students\n');
      fprintf('  debugVar = true;\n');
      fprintf('  %%/# End of hidden section\n');
      fprintf('  %% More code that students see\n\n');
    end
    % UTILITY METHODS
    function stringLine = replaceCommentLine(charLine, key, indentCount, indentChar, defaultComment)
      arguments
        charLine (1,:) char
        key (1,1) string
        indentCount (1,1) double = 0
        indentChar (1,:) char = ' '
        defaultComment (1,1) string = ""
      end
      indentStr = repmat(indentChar, 1, indentCount);
      escapedKey = regexptranslate('escape', key);
      pattern = escapedKey + "\s*(.*)$";
      commentMatch = regexp(charLine, pattern, 'tokens', 'once');
      commentMatch = string(commentMatch{1});
      if commentMatch ~= ""
        commentStr = string(commentMatch);
        if ~startsWith(commentStr, "%")
          commentStr = " " + commentStr;
        end
        stringLine = indentStr + "%" + commentStr;
      else
        stringLine = indentStr + "% " + defaultComment;
      end
    end

    function exc = exception(message,identifier)
      % exception - Create a custom MException for LiveAssignmentBuilder
      %
      % Usage:
      %   exc = LiveAssignmentBuilder.exception(message, identifier)
      %
      % Inputs:
      %   message    - Error message string
      %   identifier - Exception identifier string (e.g., 'LiveAssignmentBuilder:ParseError')
      %
      % Output:
      %   exc        - MException object
      arguments
        message (1,1) string
      end
      arguments (Repeating)
        identifier (1,1) string
      end
      identifier = join(string(["LiveAssignmentBuilder",identifier{:}]),":");
      exc = MException(identifier, message);
    end

  end

  methods
    function obj = LiveAssignmentBuilder(inputFile, opts)
      % LiveAssignmentBuilder Constructor - Generate MATLAB live scripts for assignments and answer keys.
      %
      %   obj = LiveAssignmentBuilder(inputFile, opts) converts MATLAB .m files into
      %   live scripts (.mlx) for educational purposes, generating student worksheets
      %   and instructor keys with custom parsing syntax.
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
      %       'output' (default: ".")      : Directory where the output files will be saved.
      %       'libs' (default: "")         : Path to additional libraries to include in the package.
      %       'verbose' (default: false)   : If true, prints detailed progress and status messages.
      %       'package' (default: false)   : If true, packages the generated outputs into a ZIP file.
      %       'buildContents' (default: false) : If true, generates a CONTENTS live script with
      %                                          links to all generated live scripts.
      %       'executeKey' (default: false): If true, executes the generated key files to verify
      %                                      their functionality.
      %
      %   Example:
      %   --------
      %   % Convert specific .m files into live scripts with default settings:
      %   obj = LiveAssignmentBuilder("file1.m", "file2.m");
      %
      %   % Convert .m files and specify output directory with verbosity:
      %   obj = LiveAssignmentBuilder("file1.m", "file2.m", ...
      %       struct('output', 'output_directory', 'verbose', true));
      %
      %   % Automatically find and convert all .m files in the current directory:
      %   obj = LiveAssignmentBuilder("none");
      %
      %   See also LiveAssignmentBuilder.version, LiveAssignmentBuilder.help

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

      % Set opts fields into obj properties
      obj.root         = opts.root;
      obj.output       = opts.output;
      obj.libs         = opts.libs;
      obj.verbose      = opts.verbose;
      obj.package      = opts.package;
      obj.buildContents= opts.buildContents;
      obj.executeKey   = opts.executeKey;

      % Use obj properties from here on
      if isempty(obj.root) || obj.root == ""
        obj.root = ".";
      end
      mustBeFolder(obj.root); % validate

      % Check for libs
      libDir = string(obj.libs);
      hasLibs = libDir ~= "";
      libTarget = "";
      if hasLibs
        mustBeFolder(libDir);
        libDir = dir(libDir).folder;
        [~,libTarget] = fileparts(libDir);
      end

      % Check Target directory
      target = obj.output;
      if target == "."
        [~,~] = mkdir(fullfile(target,"target"));
        target = fullfile(target,"target");
      elseif ~exist(target,"dir")
        [~,~] = mkdir(target);
      end
      % Verify
      mustBeFolder(target);

      if obj.package
        [~,~] = mkdir(fullfile(target,"_pkg"));
      end

      % parse inputs
      inputFile = string(inputFile);
      if isscalar(inputFile) && inputFile(1) == "none"
        inputFile = [];
      end
      if ~isempty(inputFile)
        fileList = fullfile(obj.root,cat(2,inputFile{:}));
      else
        dirContents = dir(fullfile(obj.root,'*.m'));
        fileList = string({dirContents.name});
        fileList = fullfile(obj.root,fileList);
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
      if obj.verbose && any(~validFiles)
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
      if obj.package
        % Create package directory
        pkgTarget = fullfile(target,"_pkg");
        [~,~] = mkdir(pkgTarget);
      end

      % Copy libraries
      if hasLibs && exist(libDir,"dir")
        % copy to target
        copyfile(libDir,fullfile(target,libTarget));
        if obj.package
          % Also copy to pkg directory
          copyfile(libDir,pkgTarget);
        end
      end

      % Run the parser
      didParse = false(1,nFiles);
      for f = 1:nFiles
        if obj.verbose, fprintf("Parsing File: '%s'...",fileList(f)); end
        S = obj.parseMToMlx( ...
          fileList(f), ...
          outputPaths(f) ...
          );
        didParse(f) = S;
        if obj.verbose
          if S
            fprintf(" Success!\n");
          else
            fprintf(" Fail!\n");
          end
        end
      end

      % report success
      if obj.verbose,fprintf("\nDone Parsing!\n");end

      % build the contents live script
      if obj.buildContents || obj.package
        if obj.verbose, fprintf('Building CONTENTS.mlx...');end
            obj.makeContents(obj.root);
        if obj.verbose, fprintf(' Done!\n');end
      end

      % determine if the build should be packaged
      if ~obj.package
        % cleanup
        if obj.verbose
          fprintf("Build Complete!\n");
        end
        return
      end

      if obj.verbose
        fprintf("Packaging... ");
      end
          obj.makePackage(obj.root);
      if obj.verbose
        fprintf("Done!\n\nBuild Complete!\n");
      end
    end

  end

  methods (Access = private)
    function makeContents(obj, root)
      % idea: group name is printed as section header: case insensitive detection
      % Name (key): Title Header
      %  Description...
      % parse _pkg folder for files
          mlxFiles = obj.getMLX(root,"_pkg");
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
                obj.tocEntry( ...
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

    function makePackage(obj, root)
      % package zip file
      tmpName = sprintf("MATLAB_Resources_%s",date);
      mkdir(tmpName);
      zipFile = strcat(tmpName,'.zip');
      % copy library files
      copyfile("lib",fullfile(tmpName,"lib"));
      % get packaged mlx files
          mlxFiles = obj.getMLX(root,"_pkg");
      % copy to tmp folder
      arrayfun(@(f)copyfile(f,tmpName),mlxFiles);
      % zip folder
      zip(zipFile,tmpName);
      % cleanup
      movefile(zipFile,"releases");
      rmdir(tmpName,'s');
    end

    function status = parseMToMlx(obj, srcFile, dstFile)
      arguments
            obj
        srcFile (1,1) string
        dstFile (1,1) string
      end
      import matlab.internal.liveeditor.openAndSave;

      status = false;

      % parse file parts
      [~,~,srcExt] = fileparts(srcFile);

      %
      if ~strcmp(srcExt,'.m'), return; end

      try
        if obj.isScriptFile(srcFile)
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
      sourceText = readlines(srcFile);
      sourceCode = string(sourceText);

      % Detect and parse sticky blocks: %!
      sourceCode = obj.parseStickyBlocks(sourceCode);
      
      % Detect and parse answer blocks: %@
      [answerIndices, sourceCode] = obj.parseAnswerBlocks(sourceCode);

      % Detect and parse multiline answer blocks: %|@ ... %||@
      try
        [mlAnswerIndices, sourceCode] = obj.parseMultilineBlocks(sourceCode);
      catch exc
        if strcmp(exc.identifier, "LiveAssignmentBuilder:parseMultilineBlocks:NoEndBlockFound")
          warning(exc.identifier, "%s in '%s'.\nFile: %s\n", exc.message, srcFile, srcFile);
          return;
        else
          throw(exc);
        end
      end

      % Detect and parse comment blocks: %# ... %/#
      try
        [commentIndices, sourceCode] = obj.parseCommentBlocks(sourceCode);
      catch exc
        if startsWith(exc.identifier, "LiveAssignmentBuilder:parseCommentBlocks:")
          warning(exc.identifier, "%s in '%s'.\nFile: %s\n", exc.message, srcFile, srcFile);
          return;
        else
          throw(exc);
        end
      end

      % Detect and parse inline answer blocks: %<@ ... %>@
      % Handle both key and worksheet code.
      parsedCode = struct();
      try
        if obj.verbose
          fprintf("----Parsing inline blocks for key----\n");
        end
        parsedCode.key = obj.parseInlineBlocks(sourceCode, "key");
        if obj.verbose
          fprintf("----Parsing inline blocks for worksheet----\n");
        end
        parsedCode.work = obj.parseInlineBlocks(sourceCode, "work");
        if obj.verbose
          fprintf("----Done parsing inline blocks----\n");
        end
      catch exc
        if startsWith(exc.identifier, "LiveAssignmentBuilder:parseInlineBlocks:")
          warning(exc.identifier, "%s in '%s'.\nFile: %s\n", exc.message, srcFile, srcFile);
          return;
        else
          throw(exc);
        end
      end
      % drop answers private info from the worksheet
      parsedCode.work(cat(1,answerIndices(:),mlAnswerIndices(:),commentIndices(:))) = [];

      % write plain code to a temporary file and then use openAndSave to convert m-file
      % to mlx-file
      tmpOut = dstFile + "_tmp.m";
      for cname = ["key","work"]
        thiscode = parsedCode.(cname);
        fid = fopen(tmpOut,'wt');
        if fid < 0, error('Error creating temporary file, check rights.'); end
        for row = 1:numel(thiscode)
          wRows = strsplit(thiscode(row),"^^n");
          for ww = wRows
            fprintf(fid,'%s\n',ww);
          end
        end
        fclose(fid);
        pause(0.5);

        % parse temp file
        if cname == "key"
          suffix = "_key";
        else
          suffix = "";
        end
        outname = dstFile + suffix + ".mlx";
        openAndSave(char(tmpOut),char(outname));
        pause(0.5);
      end

      % Run and save the key file
      if obj.executeKey
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

    function mlxFiles = getMLX(obj, root, sub)
      arguments
            obj
        root (1,1) string
      end
      arguments (Repeating)
        sub (1,1) string
      end
      pkgContents = dir(fullfile(root,sub{:},"*.mlx"));
      mlxFiles = fullfile(string({pkgContents.folder}),string({pkgContents.name}));
    end

    function str = tocEntry(obj, name, title, file, desc)
      arguments
            obj
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

    function blockInfo = detectBlocks(obj, stringCode, blockKey, fromBeginning)
      % DETECTBLOCKS Detect block markers in code
      %
      % Inputs:
      %   stringCode - Array of strings containing the code
      %   blockKey   - The block marker to detect (e.g., '%!', '%@', '%#', '%|@')
      %
      % Outputs:
      %   blockInfo  - Struct array with fields:
      %     .row   - Row index where block was detected
      %     .indent - Number of spaces before the block marker
      arguments
        obj
        stringCode (:,1) string
        blockKey (1,1) string
        fromBeginning (1,1) logical = true
      end
      % Escape special regex characters in block key
      escapedKey = regexptranslate('escape', blockKey);
      
      % Find all lines containing the block key
      allMatches = find(~cellfun(@isempty, regexp(stringCode, escapedKey, 'once'), 'unif', 1));
      nMatches = numel(allMatches);
      % Initialize block info struct
      blockInfo(1:nMatches,1) = struct('row', nan, 'indent', nan);
      
      % Process each match
      for i = 1:nMatches
        row = allMatches(i);
        line = stringCode(row);
        
        % Check if block key is at start of line or after whitespace only
        if fromBeginning
          pattern = '^(\s*)' + escapedKey;
          match = regexp(line, pattern, 'tokens', 'once');
          if isempty(match)
            % Match not at the beginning of the line, skip
            continue;
          end
          % Convert tabs to spaces for consistent indentation counting
          indentStr = match{1};
          indentSpaces = strrep(indentStr, char(9), '    '); % Convert tabs to 4 spaces
          indent = length(indentSpaces);
          % Add to block info
          blockInfo(i) = struct('row', row, 'indent', indent);
        else
          blockInfo(i) = struct('row', row, 'indent', nan);
        end
      end
      % Drop any elements in blockInfo where the row field is nan    
      blockInfo(isnan([blockInfo.row])) = [];
      if obj.verbose
        fprintf("  Detected %d blocks of type '%s'.\n", numel(blockInfo), blockKey);
      end
    end

    function stringCode = parseStickyBlocks(obj, stringCode)
      % PARSESTICKYBLOCKS Parse sticky blocks (%!)
      %
      blockInfo = obj.detectBlocks(stringCode, '%!');
      for i = 1:numel(blockInfo)
        row = blockInfo(i).row;
        indent = blockInfo(i).indent;
        charLine = stringCode{row}; % char
        
        stringCode(row) = LiveAssignmentBuilder.replaceCommentLine( ...
          charLine, ...
          '%!', ...
          indent, ...
          obj.indentChar, ...
          "DO NOT MODIFY THE FOLLOWING" ...
          );
      end
      if obj.verbose
        fprintf("    Successfully parsed %d sticky blocks.\n", numel(blockInfo));
      end
    end

    function [answerIndices, stringCode] = parseAnswerBlocks(obj, stringCode)
      % PARSEANSWERBLOCKS Parse answer blocks (%@)
      %
      % Outputs:
      %   answerIndices - Array of line indices to remove from worksheet
      
      blockInfo = obj.detectBlocks(stringCode, '%@');
      % Process each answer block
      answerIndices = [];      
      for i = 1:numel(blockInfo)
        row = blockInfo(i).row;
        indent = blockInfo(i).indent;
        charLine = stringCode{row};
        % Replace %@ with % ANSWER HERE
        stringCode(row) = LiveAssignmentBuilder.replaceCommentLine( ...
          charLine, ...
          '%@', ...
          indent, ...
          obj.indentChar, ...
          "ANSWER HERE" ...
        );
        % Find the end of this answer block
        % We need to look for either %/@, %! or %{2,}
        startIdx = row + 1;
        chunk = stringCode(startIdx:end);
        aStop = ~cellfun(@isempty,regexp(chunk,regexptranslate('escape', '%/@'),'once'),'unif',1);
        pStop = ~cellfun(@isempty,regexp(chunk,regexptranslate('escape', '%!'),'once'),'unif',1);
        cStop = ~cellfun(@isempty,regexp(chunk,'%{2,}','once'),'unif',1);
        stopIdx = find(aStop | pStop | cStop, 1, 'first');
        % skip last if note a close answer block
        stopIdx = stopIdx + startIdx - 1 - (~aStop(stopIdx));
        if isempty(stopIdx)
          stopIdx = numel(stringCode);
        end
        
        % Add indices to remove
        answerIndices = [answerIndices, startIdx:stopIdx]; %#ok<AGROW>
      end
      
      answerIndices = unique(answerIndices);
      if obj.verbose
        fprintf("    Successfully found %d answer blocks.\n", numel(answerIndices));
      end
    end

    function [mlAnswerIndices, stringCode] = parseMultilineBlocks(obj,stringCode)
      % PARSEMULTILINEBLOCKS Parse multiline answer blocks (%|@ ... %||@)
      %
      % Outputs:
      %   mlAnswerIndices   - Array of line indices to remove from worksheet
      %   sourceCode        - Array of strings containing the code with in-place modifications
      
      blockInfo = obj.detectBlocks(stringCode, '%|@');
            
      mlAnswerIndices = [];

      for i = 1:numel(blockInfo)
        startRow = blockInfo(i).row;
        startIndent = blockInfo(i).indent;
        startLine = stringCode{startRow};
        % Detect the end of the multiline answer block with priority:
        % 1. %||@ (multiline answer end)
        % 2. %!   (sticky block)
        % 3. %%   (section break, 2 or more %)

        chunk = stringCode((startRow+1):end);

        % 1. Look for %||@
        endBlock = obj.detectBlocks(chunk, '%||@');
        if ~isempty(endBlock)
          endTarget = endBlock(1).row + startRow; % inlcude for replacement
          endIndent = endBlock(1).indent;
          hasEndBlock = true;
        else
          hasEndBlock = false;
          % 2. Look for %!
          stickyBlock = obj.detectBlocks(chunk, '%!');
          if ~isempty(stickyBlock)
            endTarget = stickyBlock(1).row + startRow - 1; % exclude for replacement
            endIndent = stickyBlock(1).indent;
          else
            % 3. Look for next section (%% or more)
            sectionBreaks = ~cellfun(@isempty, regexp(chunk, '^%{2,}', 'once'), 'unif', 1);
            sectionIdx = find(sectionBreaks, 1, 'first');
            if ~isempty(sectionIdx)
              endTarget = sectionIdx + startRow - 1; % exclude for replacement
              endIndent = startIndent;
            else
              % If none found, throw an exception
              exc = LiveAssignmentBuilder.exception( ...
                "No end block found for multiline answer block", ...
                "parseMultilineBlocks", ...
                "NoEndBlockFound" ...
              );
              throw(exc);
            end
          end
        end

        % If there is a next block, ensure we do not run past it
        if (i < numel(blockInfo)) && (endTarget >= blockInfo(i+1).row)
          endTarget = blockInfo(i+1).row - 1; % exclude for replacement
          endIndent = startIndent;
        end
        
        % Replace %|@ with % --- Answer Start ---|
        stringCode(startRow) = LiveAssignmentBuilder.replaceCommentLine( ...
          startLine, ...
          '%|@', ...
          startIndent, ...
          obj.indentChar, ...
          "--- Answer Start ---|" ...
        );

        % Replace %||@ with % --- Answer End ---|
        if hasEndBlock
          stringCode(endTarget) = LiveAssignmentBuilder.replaceCommentLine( ...
            stringCode(endTarget), ...
            '%||@', ...
            endIndent, ...
            obj.indentChar, ...
            "--- Answer End ---|" ...
          );
        else
          stringCode(endTarget) = "% --- Answer End ---|^^n" + ...
           repmat(obj.indentChar, 1, endIndent) + stringCode(endTarget);
        end
        % Update the multiline answer indices
        mlAnswerIndices = [mlAnswerIndices, (startRow+1):(endTarget-1)];        
      end
      mlAnswerIndices = unique(mlAnswerIndices);
    end

    function stringCode = parseInlineBlocks(obj, stringCode, outputType)
      % PARSEINLINEBLOCKS Parse inline answer blocks (%<@ ... %>@)
      %
      % Inputs:
      %   stringCode - Array of strings containing the code
      %   outputType - 'key' or 'work'
      arguments
        obj
        stringCode (:,1) string
        outputType (1,1) string {mustBeMember(outputType, ["key","work"])}
      end
      % Detect all %<@ openers, if multiline `...` closer %>@ may be on a different line
      % and handle accordingly
      startInfo = obj.detectBlocks(stringCode, '%<@', false);
      endInfo = obj.detectBlocks(stringCode, '%>@', false);
      endRows = [endInfo.row];
      for i = 1:numel(startInfo)
        startRow = startInfo(i).row;
        % skip if line starts with % since we only want inline answers is code
        % Check that the first non-whitespace character is a '%'
        lineStr = stringCode{startRow};
        firstNonWsIdx = regexp(lineStr, '\S', 'once');
        if ~isempty(firstNonWsIdx) && lineStr(firstNonWsIdx) == '%'
          continue;
        end
        % Find the endInfo struct with the lowest row > startRow
        endIdx = find(endRows >= startRow, 1, 'first');
        if ~isempty(endIdx)
          endRowInfo = endInfo(endIdx);
        else
          exc = LiveAssignmentBuilder.exception( ...
            "No end block found for inline block", ...
            "parseInlineBlocks", ...
            "NoEndBlockFound" ...
          );
          throw(exc);
        end
        endRow = endRowInfo.row;
        if obj.verbose
          fprintf("    Parsing inline block from row %d to %d.\n", startRow, endRow);
        end
        if endRow == startRow
          % We have a single line inline block
          % replacement depends on the output type
          charLine = stringCode{startRow};
          matchPattern = regexptranslate('escape', '%<@') + "\s*([^%]*)\s*" + regexptranslate('escape', '%>@');
          codeMatch = regexp( ...
            charLine, ...
            matchPattern, ...
            'tokens', ...
            'once' ...
          );
          if outputType == "key"
            stringCode(startRow) = regexprep(charLine, matchPattern, string(codeMatch)) + "%<- " + string(codeMatch) + " ->%";
          else
            stringCode(startRow) = regexprep(charLine, matchPattern, '"%--- ANSWER HERE ---%"');
          end
        else
          % We have a multiline inline block
          % TODO: Implement multiline inline block parsing
          exc = LiveAssignmentBuilder.exception( ...
            "Multiline inline blocks not implemented", ...
            "parseInlineBlocks", ...
            "MultilineInlineBlocksNotImplemented" ...
          );
          throw(exc);
        end
      end
    end

    function [commentIndices, stringCode] = parseCommentBlocks(obj, stringCode)
      % PARSECOMMENTBLOCKS Parse comment blocks (%# ... %/#)
      %
      % Inputs:
      %   stringCode - Array of strings containing the code
      % Outputs:
      %   commentIndices - Array of line indices to remove from worksheet
      %   stringCode     - Array of strings containing the code with in-place modifications
      
      % Detect all %# openers and %/# closers
      blockInfo = obj.detectBlocks(stringCode, '%#');
      endInfo = obj.detectBlocks(stringCode, '%/#');
      startRows = [blockInfo.row];
      endRows = [endInfo.row];
      % Loop through and collect blocks, then parse for nesting
      commentIndices = [];      
      processedIndices = false(numel(stringCode),1);
      for i = 1:numel(blockInfo)
        startRow = blockInfo(i).row;
        if processedIndices(startRow)
          continue;
        end
        % If not processed, we're at an opening block
        % Find the endInfo struct with the lowest row > startRow
        endIdx = find(endRows > startRow, 1, 'first');
        if ~isempty(endIdx)
          endRowInfo = endInfo(endIdx);
        else
          exc = LiveAssignmentBuilder.exception( ...
            "No end block found for comment block", ...
            "parseCommentBlocks", ...
            "NoEndBlockFound" ...
          );
          throw(exc);
        end
        endRow = endRowInfo.row;
        

        % Handle type of comment entry
        for thisRow = startRow:(endRow-1)
          processedIndices(thisRow) = true;
          if any(startRows == thisRow)
            rowInfo = blockInfo(startRows == thisRow);
            rowLine = stringCode{thisRow};
            stringCode(thisRow) = LiveAssignmentBuilder.replaceCommentLine( ...
              rowLine, ...
              '%#', ...
              rowInfo.indent, ...
              obj.indentChar, ...
              "" ...
            );
            if ~isempty(regexp(rowLine, regexptranslate('escape', "%#") + "\s*\S+", 'once'))
              % prevent stripping the line from the worksheet
              continue;
            end
          end
          commentIndices = [commentIndices, thisRow]; %#ok<AGROW>
        end
        
        % Process the end row:
        endLine = stringCode{endRow};
        if isempty(regexp(endLine, regexptranslate('escape', "%/#") + "\s*\S+", 'once'))
          commentIndices = [commentIndices, endRow]; %#ok<AGROW>
        end
        stringCode(endRow) = LiveAssignmentBuilder.replaceCommentLine( ...
          endLine, ...
          '%/#', ...
          endRowInfo.indent, ...
          obj.indentChar, ...
          "" ...
        );
        processedIndices(endRow) = true;


        % If endIdx is the last one, break out of the loop
        if endIdx == numel(endInfo)
          break;
        end        
      end
      % Remove duplicates and sort indices
      commentIndices = unique(commentIndices);
    end

    function isScript = isScriptFile(~, fileName)
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

  end % methods

end % classdef