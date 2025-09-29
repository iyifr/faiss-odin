package example
import faiss "../faiss"
import "core:fmt"
import "core:os"
import "core:strings"

main :: proc() {
	args := os.args[1:]

	// Map of available examples
	function_map := make(map[string]proc())
	defer delete(function_map)

	function_map["flat"] = example_flat
	function_map["ivf"] = example_ivf

	if len(args) == 0 {
		faiss_version := faiss.get_version()
		// Run all examples if no arguments provided
		fmt.printfln(
			"Running ALL examples... with faiss version %s",
			strings.clone_from_cstring(faiss_version, context.temp_allocator),
		)
		fmt.println("==================================================")

		for name, example_proc in function_map {
			fmt.printf("Running example: %s\n", name)
			fmt.println("------------------------------")
			example_proc()
			fmt.println("==================================================")
		}
	} else {
		// Run specific example(s) based on arguments
		for arg in args {
			if example_proc, exists := function_map[arg]; exists {
				fmt.printf("Running example: %s\n", arg)
				fmt.println("------------------------------")
				example_proc()
				fmt.println("==================================================")
			} else {
				fmt.printf("Unknown example: %s\n", arg)
				fmt.println("Available examples:")
				for name in function_map {
					fmt.printf("  - %s\n", name)
				}
			}
		}
	}
}
