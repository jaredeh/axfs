<?php
/**
 * Library - red_black_tree.php
 *
 * $Id: red_black_tree.php,v 1.1 2010-11-28 14:29:07 emin Exp $
 *
 * This file is part of Library.
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
 * Check for correct PHP Version
 */
version_compare( PHP_VERSION, '5.0.0', '>=' )
     or die( "\nRed-Black Tree requires PHP version 5 or greater\n" );

/**
 * Red-Black Tree Node class
 *
 * <ul>
 *   <li>This class represents a Red-Black tree node</li>
 * </ul>
 *
 * @author Gokce Toykuyu, <gokce@yahoo-inc.com>
 */
class RbNode
{

    /**
     * COLOR_BLACK
     *
     * @access public
     * @var integer
     */
    const COLOR_BLACK = 0;

    /**
     * COLOR_RED
     *
     * @access public
     * @var integer
     */
    const COLOR_RED = 1;

    /**
     * Current color of the node
     *
     * @access public
     * @var integer
     */
    public $color = self::COLOR_BLACK;

    /**
     * Key
     *
     * @access public
     * @var mixed
     */
    public $key = null;

    /**
     * Info [aka value]
     *
     * @access public
     * @var mixed
     */
    public $value = null;

    /**
     * Left child of the node
     *
     * @access public
     * @var RbNode
     */
    public $left = null;

    /**
     * Right child of the node
     *
     * @access public
     * @var RbNode
     */
    public $right = null;

    /**
     * Parent of the node
     *
     * @access public
     * @var RbNode
     */
    public $parent = null;
}

/**
 * Red-Black Tree class
 *
 * <ul>
 *   <li>This class implements Red-Black tree operations</li>
 *   <li>Note that all methods could be static</li>
 *   <li>Technically RbTree could be a class of its own with
 *       root and nil fields, but to avoid having a special
 *       representation for the NIL node, for now let all
 *       the operations and the tree structure be a class
 *       contained together</li>
 * </ul>
 *
 * @author Gokce Toykuyu, <gokce@yahoo-inc.com>
 */
class RbTree
{

//-------------------------------+
// {{{ Protected instance fields |
//-------------------------------+

    /**
     * Enable debugging and debug messages
     *
     * @access protected
     * @var boolean
     */
    protected $DEBUG = false;

    /**
     * Root node of the tree
     *
     * @access protected
     * @var RbNode
     */
    protected $root = null;

    /**
     * NIL node
     *
     * @access protected
     * @var RbNode
     */
    protected $nil = null;

//-----------------------------+
// {{{ Public instance methods |
//-----------------------------+

    /**
     * Constructor
     *
     * @access public
     * @return RbTree
     */
    public function __construct()
    {
        $this->nil = new RbNode();
        $this->nil->left = $this->nil->right = $this->nil->parent = $this->nil;
        $this->root = $this->nil;
    }

    /**
     * Check if a node is a NIL node
     *
     * @access public
     * @param  RbTree
     * @param  RbNode
     */
    public function isNil( RbTree $tree, RbNode $x )
    {
        return ( $tree->nil === $x );
    }

    /**
     * Enable/disable DEBUG
     *
     * @access public
     * @param  boolean
     * @throws InvalidArgumentException
     */
    public function setDebug( $debug )
    {
        if ( !is_bool( $debug ) )
            throw new InvalidArgumentException( __METHOD__.'() debug must be a boolean' );

        $this->DEBUG = $debug;
    }

    /**
     * Insert a node to the red-black tree
     *
     * @access public
     * @param  RbTree
     * @param  RbNode
     * @return RbNode New inserted node with child and parent nodes set
     */
    public function insert( RbTree $tree, RbNode $x )
    {

        $this->binaryTreeInsert( $tree, $x );

        $newNode = $x;
        $x->color = RbNode::COLOR_RED;
        while ( $x->parent->color === RbNode::COLOR_RED )
        {
            if ( $x->parent === $x->parent->parent->left )
            {
                $y = $x->parent->parent->right;
                if ( $y->color === RbNode::COLOR_RED )
                {
                    $x->parent->color = RbNode::COLOR_BLACK;
                    $y->color = RbNode::COLOR_BLACK;
                    $x->parent->parent->color = RbNode::COLOR_RED;
                    $x = $x->parent->parent;
                }
                else
                {
                    if ( $x === $x->parent->right )
                    {
                        $x = $x->parent;
                        $this->leftRotate( $tree, $x );
                    }
                    $x->parent->color = RbNode::COLOR_BLACK;
                    $x->parent->parent->color = RbNode::COLOR_RED;
                    $this->rightRotate( $tree, $x->parent->parent );
                }
            }
            else
            {
                $y = $x->parent->parent->left;
                if ( $y->color === RbNode::COLOR_RED )
                {
                    $x->parent->color = RbNode::COLOR_BLACK;
                    $y->color = RbNode::COLOR_BLACK;
                    $x->parent->parent->color = RbNode::COLOR_RED;
                    $x = $x->parent->parent;
                }
                else
                {
                    if ( $x === $x->parent->left )
                    {
                        $x = $x->parent;
                        $this->rightRotate( $tree, $x );
                    }
                    $x->parent->color = RbNode::COLOR_BLACK;
                    $x->parent->parent->color = RbNode::COLOR_RED;
                    $this->leftRotate( $tree, $x->parent->parent );
                }
            }
        }

        $tree->root->left->color = RbNode::COLOR_BLACK;

        if ( $this->DEBUG )
        {
            assert( $tree->nil->color === RbNode::COLOR_BLACK );
            assert( $tree->root->color === RbNode::COLOR_BLACK );
        }

        return $newNode;
    }

    /**
     * Find the successor of a given node
     *
     * @access public
     * @param  RbTree
     * @param  RbNode
     * @return RbNode Note that the returned node could be the <i>RbNode</i>
     *                which equals to tree->nil
     */
    public function treeSuccessor( RbTree $tree, RbNode $x )
    {
        $nil = $tree->nil;
        $root = $tree->root;
        if ( ( $y = $x->right ) !== $nil )
        {
            while ( $y->left !== $nil )
            {
                $y = $y->left;
            }
            return $y;
        }
        else
        {
            $y = $x->parent;
            while ( $x === $y->right )
            {
                $x = $y;
                $y = $y->parent;
            }
            if ( $y === $root )
                return $nil;

            return $y;
        }
    }

    /**
     * Find the predecessor of a given node
     *
     * @access public
     * @param  RbTree
     * @param  RbNode
     * @return RbNode Note that the returned node could be the <i>RbNode</i>
     *                which equals to tree->nil
     */
    public function treePredecessor( RbTree $tree, RbNode $x )
    {
        $nil = $tree->nil;
        $root = $tree->root;
        if ( ( $y = $x->left ) !== $nil )
        {
            while ( $y->right !== $nil )
            {
                $y = $y->right;
            }
            return $y;
        }
        else
        {
            $y = $x->parent;
            while ( $x === $y->left )
            {
                if ( $y === $root )
                    return $nil;

                $x = $y;
                $y = $y->parent;
            }
            return $y;
        }
    }

    /**
     * Do a inorder tree walk and print key/value
     *
     * @access public
     * @param  RbTree
     * @param  RbNode
     */
    public function inorderTreePrint( RbTree $tree, RbNode $x )
    {

        $nil = $tree->nil;
        $root = $tree->root;

        if ( $x !== $tree->nil )
        {
            $this->inorderTreePrint( $tree, $x->left );

            echo "info=  key=".var_export( $x->key, true );

            echo "  l->key=";
            if ( $x->left === $nil )
            {
                echo "NULL";
            }
            else
            {
                echo var_export( $x->left->key, true );
            }

            echo "  r->key=";
            if ( $x->right === $nil )
            {
                echo "NULL";
            }
            else
            {
                echo var_export( $x->right->key, true );
            }

            echo "  p->key=";
            if ( $x->parent === $root )
            {
                echo "NULL";
            }
            else
            {
                echo var_export( $x->parent->key, true );
            }

            echo "  red=";
            if ( $x->color === RbNode::COLOR_RED )
            {
                echo "1";
            }
            else
            {
                echo "0";
            }

            echo "\n";
            $this->inorderTreePrint( $tree, $x->right );
        }
    }

    /**
     * Print the key and values stored in a red-black tree
     *
     * @access public
     * @param  RbTree
     */
    public function printTree( RbTree $tree )
    {
        $this->inorderTreePrint( $tree, $tree->root->left );
    }

    /**
     * Find the highest [in the tree] matching node with a given key
     *
     * @access public
     * @param  RbTree
     * @param  mixed
     * @return FALSE|RbNode
     */
    public function findKey( RbTree $tree, $q )
    {
        $x = $tree->root->left;
        $nil = $tree->nil;

        if ( $x === $nil )
            return false;

        $isEqual = $this->compare( $x->key, $q );

        while ( $isEqual !== 0 )
        {
            if ( $isEqual === 1 )
            {
                $x = $x->left;
            }
            else
            {
                $x = $x->right;
            }

            if ( $x === $nil )
                return false;

            $isEqual = $this->compare( $x->key, $q );
        }

        return $x;
    }

    /**
     * Delete a node from the tree
     *
     * @access public
     * @param  RbTree
     * @param  RbNode
     */
    public function delete( RbTree $tree, RbNode $z )
    {
        $nil = $tree->nil;
        $root = $tree->root;

        if ( ( $z->left === $nil ) || ( $z->right === $nil ) )
        {
            $y = $z;
        }
        else
        {
            $y = $this->treeSuccessor( $tree, $z );
        }

        if ( $y->left === $nil )
        {
            $x = $y->right;
        }
        else
        {
            $x = $y->left;
        }

        if ( $root === ( $x->parent = $y->parent ) )
        {
            $root->left = $x;
        }
        else
        {
            if ( $y === $y->parent->left )
            {
                $y->parent->left = $x;
            }
            else
            {
                $y->parent->right = $x;
            }
        }

        if ( $y !== $z )
        {

            if ( $this->DEBUG )
            {
                assert( $y !== $tree->nil );
            }

            if ( $y->color === RbNode::COLOR_BLACK )
                $this->deleteFixUp( $tree, $x );

            $y->left = $z->left;
            $y->right = $z->right;
            $y->parent = $z->parent;
            $y->color = $z->color;
            $z->left->parent = $z->right->parent = $y;

            if ( $z === $z->parent->left )
            {
                $z->parent->left = $y;
            }
            else
            {
                $z->parent->right = $y;
            }
            $z = null;
            unset( $z );
        }
        else
        {
            if ( $y->color === RbNode::COLOR_BLACK )
                $this->deleteFixUp( $tree, $x );

            $y = null;
            unset( $y );
        }

        if ( $this->DEBUG )
        {
            assert( $tree->nil->color === RbNode::COLOR_BLACK );
        }
    }

    /**
     * Get an enumeration of RbNodes between low and high values inclusive
     *
     * @access public
     * @param  RbTree
     * @param  mixed
     * @param  mixed
     * @return array
     */
    public function enumerate( RbTree $tree, $low, $high )
    {
        $return = array();
        $nil = $tree->nil;
        $x = $tree->root->left;
        $lastBest = $nil;
        while ( $x !== $nil )
        {
            if ( $this->compare( $x->key, $high ) === 1 )
            {
                $x = $x->left;
            }
            else
            {
                $lastBest = $x;
                $x = $x->right;
            }
        }

        while ( ( $lastBest !== $nil ) && ( $this->compare( $low, $lastBest->key ) !== 1 ) )
        {
            $return[] = $lastBest;
            $lastBest = $this->treePredecessor( $tree, $lastBest );
        }

        $return = array_reverse( $return );
        return $return;
    }

//--------------------------------+
// {{{ Protected instance methods |
//--------------------------------+

    /**
     * Do a left rotate on a given tree with pivot node x
     *
     * @access protected
     * @param  RbTree
     * @param  RbNode
     */
    protected function leftRotate( RbTree $tree, RbNode $x )
    {

        $nil = $tree->nil;

        $y = $x->right;
        $x->right = $y->left;

        if ( $y->left !== $nil )
        {
            $y->left->parent = $x;
        }

        $y->parent = $x->parent;

        if ( $x === $x->parent->left )
        {
            $x->parent->left = $y;
        }
        else
        {
            $x->parent->right = $y;
        }

        $y->left = $x;
        $x->parent = $y;

        if ( $this->DEBUG )
        {
            assert( $tree->nil->color === RbNode::COLOR_BLACK );
        }
    }

    /**
     * Do a right rotate on a given tree with pivot node y
     *
     * @access protected
     * @param  RbTree
     * @param  RbNode
     */
    protected function rightRotate( RbTree $tree, RbNode $y )
    {

        $nil = $tree->nil;

        $x = $y->left;
        $y->left = $x->right;

        if ( $x->right !== $nil )
        {
            $x->right->parent = $y;
        }

        $x->parent = $y->parent;

        if ( $y === $y->parent->left )
        {
            $y->parent->left = $x;
        }
        else
        {
            $y->parent->right = $x;
        }

        $x->right = $y;
        $y->parent = $x;

        if ( $this->DEBUG )
        {
            assert( $tree->nil->color === RbNode::COLOR_BLACK );
        }
    }

    /**
     * Do a binary tree insert
     *
     * @access protected
     * @param  RbTree
     * @param  RbNode
     */
    protected function binaryTreeInsert( RbTree $tree, RbNode $z )
    {

        $nil = $tree->nil;

        // Even though at instantiation, these are set to nil - make sure they still are ;-)
        $z->left = $z->right = $nil;

        $y = $tree->root;
        $x = $tree->root->left;

        while ( $x !== $nil )
        {
            $y = $x;
            if ( $this->compare( $x->key, $z->key ) === 1 )
            {
                $x = $x->left;
            }
            else
            {
                $x = $x->right;
            }
        }

        $z->parent = $y;

        if ( ( $y === $tree->root ) || ( $this->compare( $y->key, $z->key ) === 1 ) )
        {
            $y->left = $z;
        }
        else
        {
            $y->right = $z;
        }

        if ( $this->DEBUG )
        {
            assert( $tree->nil->color === RbNode::COLOR_BLACK );
        }
    }

    /**
     * DeleteFixUp
     *
     * @access protected
     * @param  RbTree
     * @param  RbNode
     */
    protected function deleteFixUp( RbTree $tree, RbNode $x )
    {
        $root = $tree->root->left;

        while ( ( $x->color === RbNode::COLOR_BLACK ) && ( $root !== $x ) )
        {
            if ( $x === $x->parent->left )
            {
                $w = $x->parent->right;
                if ( $w->color === RbNode::COLOR_RED )
                {
                    $w->color = RbNode::COLOR_BLACK;
                    $x->parent->color = RbNode::COLOR_RED;
                    $this->leftRotate( $tree, $x->parent );
                    $w = $x->parent->right;
                }

                if ( ( $w->right->color === RbNode::COLOR_BLACK ) &&
                     ( $w->left->color === RbNode::COLOR_BLACK ) )
                {
                    $w->color = RbNode::COLOR_RED;
                    $x = $x->parent;
                }
                else
                {
                    if ( $w->right->color === RbNode::COLOR_BLACK )
                    {
                        $w->left->color = RbNode::COLOR_BLACK;
                        $w->color = RbNode::COLOR_RED;
                        $this->rightRotate( $tree, $w );
                        $w = $x->parent->right;
                    }
                    $w->color = $x->parent->color;
                    $x->parent->color = RbNode::COLOR_BLACK;
                    $w->right->color = RbNode::COLOR_BLACK;
                    $this->leftRotate( $tree, $x->parent );
                    $x = $root;
                }
            }
            else
            {
                $w = $x->parent->left;
                if ( $w->color === RbNode::COLOR_RED )
                {
                    $w->color = RbNode::COLOR_BLACK;
                    $x->parent->color = RbNode::COLOR_RED;
                    $this->rightRotate( $tree, $x->parent );
                    $w = $x->parent->left;
                }

                if ( ( $w->right->color === RbNode::COLOR_BLACK ) &&
                     ( $w->left->color === RbNode::COLOR_BLACK ) )
                {
                    $w->color = RbNode::COLOR_RED;
                    $x = $x->parent;
                }
                else
                {
                    if ( $w->left->color === RbNode::COLOR_BLACK )
                    {
                        $w->right->color = RbNode::COLOR_BLACK;
                        $w->color = RbNode::COLOR_RED;
                        $this->leftRotate( $tree, $w );
                        $w = $x->parent->left;
                    }
                    $w->color = $x->parent->color;
                    $x->parent->color = RbNode::COLOR_BLACK;
                    $w->left->color = RbNode::COLOR_BLACK;
                    $this->rightRotate( $tree, $x->parent );
                    $x = $root;
                }
            }
        }
        $x->color = RbNode::COLOR_BLACK;

        if ( $this->DEBUG )
        {
            assert( $tree->nil->color === RbNode::COLOR_BLACK );
        }
    }

    /**
     * Compare two values
     *
     * <ul>
     *   <li> !! WARNING !! If this method is not overridden, then
     *        all the keys should either be numeric or not a numeric,
     *        otherwise a valid tree can not be formed, since string
     *        comparison would not make sense on integers e.g strcmp("3","10").
     *        In addition, values can not be compared in a mixed fashion
     *        i.e. some values compared using string comparison, and
     *        others using numeric comparison
     * </ul>
     *
     * @access protected
     * @param  mixed
     * @param  mixed
     * @return integer Return <i>integer</i> 1, if key1 is greater than key2
     *                        <i>integer</i> 0, if key1 is equal to key2
     *                        <i>integer</i> -1, if key1 is less than key2
     * @throws InvalidArgumentException
     */
    protected function compare( $key1, $key2 )
    {
        if ( !is_scalar( $key1 ) || is_bool( $key1 ) || !is_scalar( $key2 ) || is_bool( $key2 ) )
            throw new InvalidArgumentException( __METHOD__.'() keys must be a string or numeric' );

        $returnValue = null;

        switch ( true )
        {
            case ( is_numeric( $key1 ) && is_numeric( $key2 ) ):
                if ( $key1 > $key2 )
                {
                    $returnValue = 1;
                }
                else
                {
                    $returnValue = ( $key1 === $key2 ) ? 0 : -1;
                }
                return $returnValue;

                // Add more cases here...
        }

        // Unfortunately if either of the keys is not a numeric, then
        // the most logical comparison method is by their string values
        $returnValue = strcmp( "$key1", "$key2" );

        // make sure these are the exact return values, even though PHP seems to always return
        // -1,0,1 but the documentation does not explicity say it
        if ( $returnValue > 0 )
            return 1;

        if ( $returnValue < 0 )
            return -1;

        return 0;
    }
}

?>
