function s = promptUserForChoiceFromSelectionOfChoices(promptText, choiceValues)
        
    choicesString = sprintf('\n');
    for k = 1:numel(choiceValues)
        choicesString = sprintf('%s[%d] %2.3f \n', choicesString, k, choiceValues(k));
    end
    fprintf('\n%s%s', promptText, choicesString);
    s = input(sprintf('Enter index of desired value [%d-%d, ENTER=all, -1=EXIT] : ', 1, numel(choiceValues)), 's');
    if (isempty(s))
        s = 1:numel(choiceValues);
    else
        s = str2num(s);
        if (isempty(s))
            s = 1:numel(choiceValues);
        end 
    end
end
