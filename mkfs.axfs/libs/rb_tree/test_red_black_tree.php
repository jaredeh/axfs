<?php
/**
 * Library - test_red_black_tree.php
 *
 * $Id: test_red_black_tree.php,v 1.1 2010-11-28 14:29:07 emin Exp $
 *
 * This file is part of Library.
 *
 * <ul>
 *   <li>USAGE [on the command line] $>php test_red_black_tree.php</li>
 * </ul>
 *
 * Automatically generated on 02.02.2009, 17:40:54 with ArgoUML PHP module
 * (last revised $Date: 2010-11-28 14:29:07 $)
 *
 * @author     Gokce Toykuyu, <gokce@yahoo-inc.com>
 * @package    Library
 */

// +---------------------------------------------------------------------------+
// | PHP5 port of Red-Black tree implementation by Emin Martinian              |
// | - http://www.mit.edu/~emin/source_code/index.html                         |
// |                                                                           |
// | More information found at:                                                |
// | - http://en.wikipedia.org/wiki/Red-black_tree                             |
// |                                                                           |
// |   vi: set noexpandtab:                                                    |
// |   Local Variables:                                                        |
// |   indent-tabs-mode: t                                                     |
// |   End:                                                                    |
// +---------------------------------------------------------------------------+

/**
 * This file uses
 */
require_once 'red_black_tree.php';

/**
 * Get user input from command line
 *
 * @access public
 * @return mixed
 */
function readUserInput() {
    do $input = trim(fgets(STDIN)); while($input === '');

    // Don't allow float inputs - cast the numeric input to int
    if(is_numeric($input))
        $input = (int) $input;

    return $input;
}

//------------------+
// {{{ start main() |
//------------------+

$newKey = $newKey2 = 0;
$option = 0;
$tree = new RbTree();
while($option !== '8') {
    printf("choose one of the following:\n");
    printf("(1) add to tree\n(2) delete from tree\n(3) query\n");
    printf("(4) find predecessor\n(5) find sucessor\n(6) enumerate\n");
    printf("(7) print tree\n(8) quit\n");
    $option = readUserInput();
    switch($option)
    {
        case '1':
            printf("type key for new node\n");
            $newKey = readUserInput();
            $newNode = new RbNode();
            $newNode->key = $newKey;
            $tree->insert($tree, $newNode);
            break;

        case '2':
            printf("type key of node to remove\n");
            $newKey = readUserInput();
            if(($newNode = $tree->findKey($tree, $newKey)) !== false) $tree->delete($tree,$newNode);
            else printf("key not found in tree, no action taken\n");
            break;

        case '3':
            printf("type key of node to query for\n");
            $newKey = readUserInput();
            if(($newNode = $tree->findKey($tree,$newKey)) !== false) {
                printf("data exists in tree with key {$newKey}\n");
            } else {
                printf("data not in tree\n");
            }
            break;

        case '4':
            printf("type key of node to find predecessor of\n");
            $newKey = readUserInput();
            if(($newNode = $tree->findKey($tree,$newKey)) !== false) {
                $newNode = $tree->treePredecessor($tree,$newNode);
                if($tree->isNil($tree, $newNode)) {
                    printf("there is no predecessor for that node (it is a minimum)\n");
                } else {
                    printf("predecessor has key %s\n",var_export($newNode->key, true));
                }
            } else {
                printf("data not in tree\n");
            }
            break;

        case '5':
            printf("type key of node to find successor of\n");
            $newKey = readUserInput();
            if(($newNode = $tree->findKey($tree,$newKey)) !== false) {
                $newNode = $tree->treeSuccessor($tree,$newNode);
                if($tree->isNil($tree, $newNode)) {
                    printf("there is no successor for that node (it is a maximum)\n");
                } else {
                    printf("successor has key %s\n", var_export($newNode->key, true));
                }
            } else {
                printf("data not in tree\n");
            }
            break;

        case '6':
            printf("type low and high keys to see all keys between them\n");
            printf("low:\n");
            $newKey = readUserInput();
            printf("high:\n");
            $newKey2 = readUserInput();
            printf("\n");
            $enumResult = $tree->enumerate($tree,$newKey,$newKey2);
            if(is_array($enumResult)) {
                foreach($enumResult as $newNode) {
                    printf("%s\n",var_export($newNode->key, true));
                }
                printf("\n");
            }
            break;
        case 7:
            $tree->printTree($tree);
            break;
        case 8:
            exit(0);

        default:
            printf("Invalid input; Please try again.\n");
    }
}

exit(0);
?>
