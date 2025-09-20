%% Example: Function Evaluation and Plotting
% This example demonstrates the LiveAssignmentBuilder parsing syntax for creating
% educational MATLAB live scripts with student worksheets and instructor keys.
%
% The example shows how to:
%
% * Use sticky blocks to prevent editing
% * Create answer blocks for student responses
% * Include inline expressions for student completion
% * Use multiline answer blocks for code completion
% * Implement comment blocks for instructor notes
%
% _Author_: Khris Griffis, Ph.D.
% 
% _Date_: September 2025
%% Function Definition
% First, let's define a simple mathematical function to work with:

%!
y = @(x) x.^2 + 2.*x + 1;
%! END OF PROTECTED CODE

%% Student Task: Evaluate Function in a Loop
% In this section, you will create code to evaluate our function at multiple
% x-values and create a plot.
%
% Use the |for|-loop below to evaluate the function |y| at 
% |x| = ${1,\, 1.1,\, \ldots,\,  3}$.
% 
% This section sets up the variables for the student task. 
% The student will need to complete the array size calculation and loop.
% The instructor key will show the complete solution.

%! Protected variable setup
new_x = 1:0.1:3;

% Preallocate the output array
% Complete the line below to create an array of the correct size:
new_y = zeros(%<@size(new_x)%>@);

% Complete the for loop below to evaluate the function at each x-value:
for ix = 1:length(new_x)
    %|@ START ANSWER ---| Hint: Use new_x(ix) to get the current x-value
    % Then call the function: new_y(ix) = exampleFunction(x_value)
    x_value = new_x(ix);
    new_y(ix) = y(x_value);
    %||@
end

%% Advanced Loop Example
% Here's an example with nested indentation:

% Initialize counter
idx = 0;
while idx < 5
    %# Don't forget to increment your iterator!
    idx = idx + 1;
    %/#
    
    % Calculate some values
    if idx > 2
        %# This is a nested comment block
        %# It demonstrates proper indentation handling
        temp_value = idx * 2;
        %/#
        
        % Complete this calculation
        result = temp_value + %<@idx%>@;
        %# Optionally display the result with fprintf
        fprintf('Iteration %d: result = %d\n', idx, result);
        %/#
    end
end

%% Visualization
% Create a plot to visualize the results:

%@ Optional: Visualize the new results
figure('Position', [100, 100, 800, 600]);
plot(new_x, new_y, 'o-', 'MarkerSize', 6, 'LineWidth', 2);
xlabel('x values');
ylabel('y = x^2 + 2x + 1');
title('Function Evaluation Results');
grid on;

%% Analysis Questions
% Answer the following questions based on your results:
%
% 1. What is the minimum value of y in your results?
%
%# _Answer_:
% The minimum value occurs at x = -1 and y = 0
%/#
%    
% 2. What is the maximum value of y for x in the range [1, 3]?
%
%# _Answer_:
% The maximum value occurs at x = 3 and y = 16
%/#
%    
% 3. Is this function increasing or decreasing over the interval [1, 3]?
% 
%# _Answer_:
% The function is increasing over this interval since the
% derivative $y' = 2x + 2 > 0$ for all $x > -1$
%/#

%% Advanced Exercise (Optional)
% For advanced students, try this additional challenge:
% 
% This is an optional advanced section that won't appear in the worksheet.
% but will be visible in the instructor key.
% Students who finish early can attempt this bonus problem.
%
% *Bonus*: Modify the code above to evaluate the function at x-values
% from -2 to 4 with a step size of 0.05, and create a comparison
% plot showing both the original range [1,3] and the extended range [-2,4].
%
% Hint: You'll need to create a new x-array and evaluate the function
% at those points, then use subplot or hold on to display both plots.
%       

%|@
extended_x = -2:0.05:4;
extended_y = exampleFunction(extended_x);

figure;
subplot(2,1,1);
plot(new_x, new_y, 'o-', 'MarkerSize', 4, 'LineWidth', 1.5);
title('Original Range [1,3]');
grid on;

subplot(2,1,2);
plot(extended_x, extended_y, '-', 'LineWidth', 2);
title('Extended Range [-2,4]');
grid on;
%||@

%% Summary
% In this example, you learned how to:
% 
% # Define and call functions in MATLAB
% # Use loops to evaluate functions at multiple points
% # Preallocate arrays for better performance
% # Create plots to visualize mathematical functions
% # Analyze function behavior over different intervals
%
%# 
%% Instructor Notes:
% This example demonstrates all the key parsing features:
%
% * Sticky blocks (%!) for protected code
% * Inline answer blocks (%<@ %>@) for single expressions
% * Multiline answer blocks (%|@ %||@) for code completion
% * Comment blocks (%# %/#) for instructor-only content
%
% The example progresses from basic to advanced concepts and includes
% both computational and analytical components.
%/#