<?php
namespace CIC\Cicbase\Property\TypeConverter;

use CIC\Cicbase\Domain\Model\FileReference;

class FileReferenceConverter extends \TYPO3\CMS\Extbase\Property\TypeConverter\PersistentObjectConverter {

	/**
	 * The source types this converter can convert.
	 *
	 * @var array<string>
	 * @api
	 */
	protected $sourceTypes = array('array');

	/**
	 * The target type this converter can convert to.
	 *
	 * @var string
	 * @api
	 */
	protected $targetType = '\TYPO3\CMS\Extbase\Domain\Model\FileReference';

	/**
	 * The priority for this converter.
	 *
	 * @var integer
	 * @api
	 */
	protected $priority = 2;

	/**
	 * @var \CIC\Cicbase\Factory\FileReferenceFactory
	 * @inject
	 */
	protected $fileFactory;

	/**
	 * @var \CIC\Cicbase\Persistence\LimboInterface
	 * @inject
	 */
	protected $limbo;


	/**
	 * @param Tx_Extbase_Configuration_ConfigurationManagerInterface $configurationManager
	 * @return void
	 */
	public function injectConfigurationManager(\TYPO3\CMS\Extbase\Configuration\ConfigurationManagerInterface $configurationManager) {
		$this->configurationManager = $configurationManager;
		$this->settings = $this->configurationManager->getConfiguration(\TYPO3\CMS\Extbase\Configuration\ConfigurationManagerInterface::CONFIGURATION_TYPE_SETTINGS);
	}

	/**
	 * @param mixed $source
	 * @return array
	 */
	public function getSourceChildPropertiesToBeConverted($source) {
		return array();
	}

	/**
	 * This implementation always returns TRUE for this method.
	 *
	 * @param mixed $source the source data
	 * @param string $targetType the type to convert to.
	 * @return boolean TRUE if this TypeConverter can convert from $source to $targetType, FALSE otherwise.
	 * @api
	 */
	public function canConvertFrom($source, $targetType) {
		return TRUE;
	}

	/**
	 * Return the target type this TypeConverter converts to.
	 * Can be a simple type or a class name.
	 *
	 * @return string
	 * @api
	 */
	public function getSupportedTargetType() {
		return $this->targetType;
	}

	/**
	 * @param mixed $source
	 * @param string $targetType
	 * @param array $convertedChildProperties
	 * @param null|\TYPO3\CMS\Extbase\Property\PropertyMappingConfigurationInterface $configuration
	 * @return null|object|\TYPO3\CMS\Extbase\Domain\Model\FileReference|\TYPO3\CMS\Extbase\Error\Error
	 * @throws Tx_Extbase_Configuration_Exception
	 */
	public function convertFrom($source, $targetType, array $convertedChildProperties = array(), \TYPO3\CMS\Extbase\Property\PropertyMappingConfigurationInterface $configuration = NULL) {
		$thisClass = get_class($this);
		$propertyPath = $configuration->getConfigurationValue($thisClass, 'propertyPath');

		if(!$propertyPath) {
			$propertyPath = 'file';
			$key = '';
		} else {
			$key = $propertyPath;
		}
		if(!$this->fileFactory->wasUploadAttempted($propertyPath)) {
			$fileReference = $this->limbo->getHeld($key);
			if($fileReference instanceof FileReference) {
				return $fileReference;
			} else {
				// this is where we end up if no file upload was attempted (eg, form was submitted without a value
				// in the upload field, and we were unable to find a held file. In this case, return false, as though
				// nothing was ever posted.
				return NULL;
			}
		}

		// Otherwise, we create a new file object. Note that we use the fileFactory to turn $_FILE data into
		// a proper file object. Elsewhere, we use the limbo to retrieve file objects, even those that
		// haven't yet been persisted to the database;
		$allowedTypes = $configuration->getConfigurationValue($thisClass, 'allowedTypes');
		$maxSize = $configuration->getConfigurationValue($thisClass, 'maxSize');
//		if(!$allowedTypes) {
//			$allowedTypes = $this->settings['file']['fileAllowedMime'];
//		}
//		if(!$maxSize) {
//			$maxSize = $this->settings['file']['fileMaxSize'];
//		}
//
//		// Too risky to use this type converter without some settings in place.
//		if(!$maxSize) {
//			throw new \TYPO3\CMS\Extbase\Configuration\Exception('Before you can use the file type converter, you must set a
//			 fileMaxSize value in the settings section of your extension typoscript, or in the file type converter
//			 configuration.', 1337043345);
//		}
//		if (!is_array($allowedTypes) && count($allowedTypes) == 0) {
//			throw new \TYPO3\CMS\Extbase\Configuration\Exception('Before you can use the file type converter, you must configure
//			 fileAllowedMime settings section of your extension typoscript, or in the file type converter
//			 configuration.', 1337043346);
//		}

		$additionalReferenceProperties = $configuration->getConfigurationValue($thisClass, 'additionalReferenceProperties');

		$reference = $this->fileFactory->createFileReference($propertyPath, $additionalReferenceProperties, $allowedTypes, $maxSize);

		if ($targetType == 'CIC\Cicbase\Domain\Model\FileReference') {
			return $reference;
		}

		# Otherwise build a collection
		$storage = $this->objectManager->getEmptyObject('TYPO3\CMS\Extbase\Persistence\ObjectStorage');
		$storage->attach($reference);
		return $storage;
	}

}

?>