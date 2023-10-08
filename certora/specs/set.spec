
//
// Under approximation warning: checking a single chain ID at at time.
//
methods{
   // function getFacilitatorsListLen() external returns (uint256) envfree;
   // function getSupportedChainsLength() external returns (uint256) envfree;
    function getRepresentedVotersSize(address,uint256) external returns (uint256) envfree;
 
}

definition MAX_UINT256() returns uint256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
definition MAX_UINT256Bytes32() returns bytes32 = to_bytes32(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF); //todo: remove once CERT-1060 is resolved

definition TWO_TO_160() returns uint256 = 0x10000000000000000000000000000000000000000;


/**
* Set map entries point to valid array entries
* @notice an essential condition of the set, should hold for evert Set implementation 
* @return true if all map entries points to valid indexes of the array.
*/
definition MAP_POINTS_INSIDE_ARRAY() returns bool = forall address rep. forall bytes32 a. mirrorMap[rep][a] <= mirrorArrayLen[rep];
/**
* Set map is the inverse function of set array. 
* @notice an essential condition of the set, should hold for evert Set implementation 
* @notice this condition depends on the other set conditions, but the other conditions do not depend on this condition.
*          If this condition is omitted the rest of the conditions still hold, but the other conditions are required to prove this condition.
* @return true if for every valid index of the array it holds that map(array(index)) == index + 1.
*/
definition MAP_IS_INVERSE_OF_ARRAY() returns bool = forall address rep. forall uint256 i. (i < mirrorArrayLen[rep]) => to_mathint(mirrorMap[rep][mirrorArray[rep][i]]) == i + 1;

/**
* Set array is the inverse function of set map
* @notice an essential condition of the set, should hold for evert Set implementation 
* @return true if for every non-zero bytes32 value stored in in the set map it holds that array(map(value) - 1) == value
*/
definition ARRAY_IS_INVERSE_OF_MAP() returns bool = forall address rep. forall bytes32 a. forall uint256 b. 
            ((to_mathint(b) == mirrorMap[rep][a]-1) => (mirrorMap[rep][a] != 0)) => (mirrorArray[rep][b] == a);




/**
* load array length
* @notice a dummy condition that forces load of array length, using it forces initialization of  mirrorArrayLen
* @return always true
*/
definition CVL_LOAD_ARRAY_LENGTH(address representative, uint256 chainId) returns bool
             = (getRepresentedVotersSize(representative, chainId) == getRepresentedVotersSize(representative, chainId));

/**
* Set-general condition, encapsulating all conditions of Set 
* @notice this condition recaps the general characteristics of Set. It should hold for all set implementations i.e. AddressSet, UintSet, Bytes32Set
* @return conjunction of the Set three essential properties.
*/
definition SET_INVARIANT(address representative, uint256 chainId) returns bool = 
        MAP_POINTS_INSIDE_ARRAY() && MAP_IS_INVERSE_OF_ARRAY() && ARRAY_IS_INVERSE_OF_MAP() &&  CVL_LOAD_ARRAY_LENGTH(representative, chainId); 

/**
 * Size of stored value does not exceed the size of an address type.
 * @notice must be used for AddressSet, must not be used for Bytes32Set, UintSet
 * @return true if all array entries are less than 160 bits.
 **/
definition VALUE_IN_BOUNDS_OF_TYPE_ADDRESS() returns bool = (forall address rep. forall uint256 i. (mirrorArray[rep][i]) & to_bytes32(max_uint160) == mirrorArray[rep][i]);

/**
 * A complete invariant condition for AddressSet
 * @notice invariant addressSetInvariant proves that this condition holds
 * @return conjunction of the Set-general and AddressSet-specific conditions
 **/
definition ADDRESS_SET_INVARIANT(address representative, uint256 chainId) returns bool =
             SET_INVARIANT(representative, chainId) && VALUE_IN_BOUNDS_OF_TYPE_ADDRESS();

/**
 * A complete invariant condition for UintSet, Bytes32Set
 * @notice for UintSet and Bytes2St no type-specific condition is required because the type size is the same as the native type (bytes32) size
 * @return the Set-general condition
 **/
definition UINT_SET_INVARIANT(address representative, uint256 chainId) returns bool = SET_INVARIANT(representative, chainId);

/**
 * Out of bound array entries are zero
 * @notice A non-essential  condition. This condition can be proven as an invariant, but it is not necessary for proving the Set correctness.
 * @return true if all entries beyond array length are zero
 **/
definition ARRAY_OUT_OF_BOUND_ZERO() returns bool = forall address rep. forall uint256 i. (i >= mirrorArrayLen[rep]) => (mirrorArray[rep][i] == to_bytes32(0));

// For CVL use

/**
 * ghost mirror map, mimics Set map
 **/
ghost mapping(address => mapping(bytes32 => uint256)) mirrorMap{ 
    init_state axiom forall address rep. forall bytes32 a. mirrorMap[rep][a] == 0;
    axiom forall address rep. forall bytes32 a. mirrorMap[rep][a] >= 0 && mirrorMap[rep][a] <= MAX_UINT256(); //todo: remove once https://certora.atlassian.net/browse/CERT-1060 is resolved
    
}

/**
 * ghost mirror array, mimics Set array
 **/
ghost mapping(address => mapping(uint256 => bytes32)) mirrorArray{
    init_state axiom forall address rep. forall uint256 i. mirrorArray[rep][i] == to_bytes32(0);
    axiom forall address rep. forall uint256 a. mirrorArray[rep][a] & MAX_UINT256Bytes32() == mirrorArray[rep][a];
//    axiom forall uint256 a. to_uint256(mirrorArray[a]) >= 0 && to_uint256(mirrorArray[a]) <= MAX_UINT256(); //todo: remove once CERT-1060 is resolved
//axiom forall uint256 a. to_mathint(mirrorArray[a]) >= 0 && to_mathint(mirrorArray[a]) <= MAX_UINT256(); //todo: use this axiom when cast bytes32 to mathint is supported
}

/**
 * ghost mirror array length, mimics Set array length
 * @notice ghost includes an assumption about the array length. 
  * If the assumption were not written in the ghost function it should be written in every rule and invariant.
  * The assumption holds: breaking the assumptions would violate the invariant condition 'map(array(index)) == index + 1'. Set map uses 0 as a sentinel value, so the array cannot contain MAX_INT different values.  
  * The assumption is necessary: if a value is added when length==MAX_INT then length overflows and becomes zero.
 **/
ghost mapping(address => uint256) mirrorArrayLen{
    init_state axiom forall address rep. mirrorArrayLen[rep] == 0;
    axiom forall address rep. to_mathint(mirrorArrayLen[rep]) < TWO_TO_160() - 1; //todo: remove once CERT-1060 is resolved
}


/**
 * hook for Set array stores
 * @dev user of this spec must replace _list with the instance name of the Set.
 **/
hook Sstore _votersRepresented [KEY address rep] [KEY uint256 chain] .(offset 0)[INDEX uint256 index] bytes32 newValue (bytes32 oldValue) STORAGE {
    mirrorArray[rep][index] = newValue;
}

/**
 * hook for Set array loads
 * @dev user of this spec must replace _list with the instance name of the Set.
 **/
hook Sload bytes32 value _votersRepresented [KEY address rep] [KEY uint256 chain] .(offset 0)[INDEX uint256 index] STORAGE {
    require(mirrorArray[rep][index] == value);
}
/**
 * hook for Set map stores
 * @dev user of this spec must replace _list with the instance name of the Set.
 **/
hook Sstore _votersRepresented [KEY address rep] [KEY uint256 chain] .(offset 32)[KEY bytes32 key] uint256 newIndex (uint256 oldIndex) STORAGE {
      mirrorMap[rep][key] = newIndex;
}

/**
 * hook for Set map loads
 * @dev user of this spec must replace _list with the instance name of the Set.
 **/
hook Sload uint256 index _votersRepresented [KEY address rep] [KEY uint256 chain] .(offset 32)[KEY bytes32 key] STORAGE {
    require(mirrorMap[rep][key] == index);
}

/**
 * hook for Set array length stores
 * @dev user of this spec must replace _list with the instance name of the Set.
 **/
hook Sstore _votersRepresented  [KEY address rep] [KEY uint256 chain] .(offset 0).(offset 0) uint256 newLen (uint256 oldLen) STORAGE {
        mirrorArrayLen[rep] = newLen;
}

/**
 * hook for Set array length load
 * @dev user of this spec must replace _votersRepresented with the instance name of the Set.
 **/
hook Sload uint256 len _votersRepresented  [KEY address rep] [KEY uint256 chain] .(offset 0).(offset 0) STORAGE {
    require mirrorArrayLen[rep] == len;
}

/**
 * main Set general invariant
 **/
invariant setInvariant(address representative, uint256 chainId)
    SET_INVARIANT(representative, chainId);


/**
 * main AddressSet invariant
 * @dev user of the spec should add 'requireInvariant addressSetInvariant();' to every rule and invariant that refer to a contract that instantiates AddressSet  
 **/
invariant addressSetInvariant(address representative, uint256 chainId)
    ADDRESS_SET_INVARIANT(representative, chainId);

/**
* @title Length of AddressSet is less than 2^160
* @dev the assumption is safe because there are at most 2^160 unique addresses
* @dev the proof of the assumption is vacuous because length > loop_iter
*/
invariant set_size_leq_max_uint160(address representative, uint256 chainId)
	      getRepresentedVotersSize(representative, chainId)  < max_uint160;

