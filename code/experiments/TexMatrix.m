function TexMatrix(varargin)
%TexMatrix provides TeX code for the given matrix
%
%   Input Arguments: (A, digits, prop)
%   ================
%   A = A matrix of size mxn
%   digits = the maximum number of digits to include when converting the 
%            matrix A into a string representation. The default number of 
%            digits is 4.
%   prop   = string array used to specify certain properties.
%           'text' e.g. \left[	 48.6 \; 66.6\right]
%           'tab'  e.g. \begin{tabular}{|c|c|} \hline
%                   	    $48.6$ & $66.6$ \\ \hline 
%                       \end{tabular}%
%           'rowlines' adds \hline at the end of each row
%           {'rowheader', {'A'}} e.g. \left( \begin{array}{lcc}
%                                         A & 48.6 & 66.6 \\
%                                     \end{array} \right)
%           {'colheader', {'RSS','WRSS'}, 'rowheader', {'Model','A1'}} e.g.
%                                     \left( \begin{array}{lcc}
%                                         Model & RSS & WRSS \\
%                                         A1 & 48.62 & 66.59 \\
%                                     \end{array} \right)
%
%   Output Arguments:
%   =================
%   (none) The output is written to the screen, from where it easily can be
%   copy pasted into a TeX document.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fieldnames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
A = [];
digits = [];
prop = {};
matrix = true;
rowlines = false;
intext = false;
rowheader = false;
RowNames = {''};
colheader = false;
ColNames = {''};
net = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Processes the input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch nargin
    case 1,
        A = varargin{1};
    case 2,
        A = varargin{1};
        if isnumeric(varargin{2}),
            digits = varargin{2};
        else
            prop = varargin{2};
        end
    case 3,
        A = varargin{1};
        digits = varargin{2};
        prop = varargin{3};
    otherwise,
        error('TNsMatlab_toolbox:TexMatrix:InputNumberError','Wrong number of input arguments')
end
if ~isempty(prop) && iscell(prop),
    for i=1:numel(prop),
        if strcmp(prop{i},'tab'),
            matrix = false;
        end
        if strcmp(prop{i},'text'),
            intext = true;
        end
        if strcmp(prop{i},'net'),
            net = true;
        end
        if strcmp(prop{i},'colheader'),
            colheader = true;
            ColNames = prop{i+1};
            if ~iscellstr(ColNames),
                error('TNsMatlab_toolbox:TexMatrix:ColHeaderError','All elements in column header cell array are not strings')
            end
            if numel(ColNames) ~= size(A,2),
                error('TNsMatlab_toolbox:TexMatrix:ColHeaderNumber','The list of column headers does not contain as many elements as columns in the matrix')
            end
        end
        if strcmp(prop{i},'rowheader'),
            rowheader = true;
            RowNames = prop{i+1};
            if ~iscellstr(RowNames),
                error('TNsMatlab_toolbox:TexMatrix:RowHeaderError','All elements in row header cell array are not strings')
            end
            if colheader,
                if numel(RowNames) ~= size(A,1)+1,
                    error('TNsMatlab_toolbox:TexMatrix:RowHeaderNumber','The list of row headers does not contain as many elements as rows in the matrix plus one column header')
                end
            else
                if numel(RowNames) ~= size(A,1),
                    error('TNsMatlab_toolbox:TexMatrix:RowHeaderNumber','The list of row headers does not contain as many elements as rows in the matrix')
                end
            end
        end
    end
else
        if strcmp(prop,'tab'),
            matrix = false;
        end
        if strcmp(prop,'text'),
            intext = true;
        end
end

if isempty(digits),
    digits = 5;
end

[r c] = size(A);

%Begin
text = sprintf('%%Copy and paste the following:\n');
if ~intext,
    % Prints the definition of the size of the matrix or table
    if rowheader,
        if matrix,
            cc = 'l';
        else
            cc = '|l|';
        end
    else
        cc = '';
    end
    % Standard for equations and tables
    if matrix,
        for i = 1:c,
            cc = [cc 'c'];
        end
        text = sprintf('%s\\left(%%\n',text);
        text = sprintf('%s\\begin{array}{%s}\n',text,cc);
    else
        if isempty(c),
            cc = '|';
        end
        for i = 1:c,
            cc = [cc 'c|'];
        end
        text = sprintf('%s\\begin{tabular}{%s}\n\t\\hline\n',text,cc);
    end
    
    % Prints the column header
    if colheader,
        text = sprintf('%s\t',text);
        if rowheader,
            cc =  [RowNames{1} ' & '];
        else
            cc = '';
        end
        for i = 1:c-1,
            cc = [cc ColNames{i} ' & '];
        end
        cc = [cc ColNames{end}];
        if matrix,
            text = sprintf('%s%s \\\\\n',text,cc);
        else
            text = sprintf('%s%s \\\\ \\hline \n',text,cc);
        end
    end

    % Prints the matrix
    for i = 1:r,    
        if rowheader,
            if colheader,
                text = sprintf('%s\t%s &',text,RowNames{i+1});
            else
                text = sprintf('%s\t%s &',text,RowNames{i});
            end
        else
            text = sprintf('%s\t',text);
        end
        for j = 1:c,
            if ~isempty(digits),
                if ~isfinite(A(i,j)), %NaN
                    textext = num2str(A(i,j));
                elseif ~mod(A(i,j),1), %Integer 
                        textext = num2str(A(i,j));                    
                elseif abs(A(i,j))<5*10^-(digits+1),
                    if net, % Removes signs from zero elements
                        A(i,j) = 0;
                        textext = num2str(A(i,j));
                    else
%                         if abs(A(i,j)) > 0,
%                             textext = [num2str(round(A(i,j) ./ 10.^floor(log10(abs(A(i,j)))))) '*10^{' num2str(floor(log10(abs(A(i,j))))) '}'];
%                         end
                        textext = num2str(A(i,j),1);
                    end
                else
                    textext = num2str(A(i,j), digits);
                end
            else
                if abs(A(i,j))<5*10^-5,
                    % Removes signs from zero elements
                    A(i,j) = 0;
                end
                textext = num2str(A(i,j), 4);
            end
            if j < c,
                if matrix,
                    text = sprintf('%s %s &',text,textext);
                else
                    text = sprintf('%s $%s$ &',text,textext);
                end
            else
                if matrix,
                    text = sprintf('%s %s',text,textext);
                else
                    text = sprintf('%s $%s$',text,textext);
                end
            end
        end
        if matrix,
            text = sprintf('%s \\\\\n',text);
        else
            if rowlines,
                text = sprintf('%s \\\\ \\hline \n',text);
            else
                text = sprintf('%s \\\\ \n',text);
            end
        end
    end

    %End
    if matrix,
        text = sprintf('%s\\end{array}%%\n\\right)',text);
    else
        if rowlines,
            text = sprintf('%s\\end{tabular}%%',text);
        else
            text = sprintf('%s\t\\hline \n\\end{tabular}%%',text);
        end
    end
else
    % Only adds white spaces for using in text
    text = sprintf('%s\\left[',text);
    % Prints the matrix
    for i = 1:r,    
        text = sprintf('%s\t',text);
        for j = 1:c,
            if ~isempty(digits),
                if abs(A(i,j))<5*10^-(digits+1),
                    % Removes signs from zero elements
                    A(i,j) = 0;
                end
                textext = num2str(A(i,j), digits);
            else
                if abs(A(i,j))<5*10^-5,
                    % Removes signs from zero elements
                    A(i,j) = 0;
                end
                textext = num2str(A(i,j), 4);
            end
            if j < c,
                text = sprintf('%s %s \\;',text,textext);
            else
                text = sprintf('%s %s',text,textext);
            end
        end
        if i < r,
            text = sprintf('%s \\\\\n',text);
        end
    end

    %End
    text = sprintf('%s\\right]',text);
end

%Prints it to the screen
disp(text)
end

% Following code is not in use, since the symbolic toolbox has a latex
% command
function textext = frac(text)

div = strfind(text,'/');
if strcmp(text(div-1),')'),
    if strcmp(text(1),'('),
        textext = ['\frac{' text(2:div-2) '}'];
    else
        textext = ['\frac{' text(1:div-1) '}'];
    end
else
    textext = ['\frac{' text(1:div-1) '}'];
end
if strcmp(text(div+1),'('),
    if strcmp(text(end),')'),
        textext = [textext '{' text(div+2:end-1) '}'];
    else
        textext = [textext '{' text(div+1:end) '}'];
    end
else
    textext = [textext '{' text(div+1:end) '}'];
end
textext
end

function textext = index(text),
textext = '';
last = 1;
pos = strfind(text,'_');
for i = 1:length(pos)
    posend = regexp(text(pos+1:end), '[+-*/^]')
    textext = [textext text(last:pos(i)) '{' text(pos(i)+1:posend(1)-1) '}']
    last = posend(1);
end
end 

