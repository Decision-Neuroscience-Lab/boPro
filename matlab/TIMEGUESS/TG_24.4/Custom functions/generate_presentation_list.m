function [presentation_list] = generate_presentation_list(pair, num_repeats)

list_one = [pair; ones(1, numel(pair))];
list_two = [pair; ones(1, numel(pair)) + 1];

presentation_list = cat(2, list_one, list_two);
presentation_list = repmat(presentation_list, 1, num_repeats);