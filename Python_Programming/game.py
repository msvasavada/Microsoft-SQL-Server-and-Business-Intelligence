def get_digits(number):
    return [int(digit) for digit in str(number)]

def step_1():
    # Step 1: Ask the user to think of a 4-digit number
    number = int(input("Think of a 4-digit number: "))
    return number

def step_2(number):
    # Step 2: Add all digits and subtract the sum from the original number
    digits = get_digits(number)
    sum_of_digits = sum(digits)
    result = number - sum_of_digits
    print(f"Step 2 result: {result}")
    return result

def step_3(result):
    # Step 3: Ask user to enter one digit from the result
    entered_digit = int(input(f"Enter a digit from the result {result}: "))
    
    # Get the remaining digits from the result
    remaining_digits = [int(digit) for digit in str(result) if int(digit) != entered_digit]
    
    return entered_digit, remaining_digits

def step_4(remaining_digits, entered_digit):
    # Step 4: Handle based on the sum of the remaining digits
    sum_remaining_digits = sum(remaining_digits)
    
    if sum_remaining_digits < 9:
        result_digit = 9 - sum_remaining_digits
    elif 9 <= sum_remaining_digits <= 17:
        result_digit = 9 * 2 - sum_remaining_digits
    else:
        result_digit = 0  # For any case above, just return 0 as a default (though the logic might be different)
    
    print(f"Calculated result based on your input: {result_digit}")
    return result_digit

# Putting everything together
def main():
    number = step_1()
    result = step_2(number)
    entered_digit, remaining_digits = step_3(result)
    step_4(remaining_digits, entered_digit)

if __name__ == "__main__":
    main()
